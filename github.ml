(* ************************************************************************** *)
(* Project: GitHub API v3 bindings in OCaml                                   *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version on GitHub: https://github.com/db0company/GitHub-API-OCaml   *)
(* ************************************************************************** *)

open Yojson.Basic.Util

type 'a t = Success of 'a | Error of string

(* ************************************************************************** *)
(* Requirements                                                               *)
(* ************************************************************************** *)

let base_url = "https://api.github.com/"

let connection = ref None

let writer accum data =
  Buffer.add_string accum data;
  String.length data
let result = Buffer.create 4096
let error_buffer = ref ""

(* Connect to the API using your username and password on GitHub.             *)
let connect ?(agent = "") username password =
  let agent = if (String.length agent) = 0 then username else agent in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let c = Curl.init () in
  connection := Some c;
  Curl.set_errorbuffer c error_buffer;
  Curl.set_writefunction c (writer result);
  Curl.set_followlocation c true;
  Curl.set_httpauth c [Curl.CURLAUTH_BASIC];
  Curl.set_userpwd c (username ^ ":" ^ password);
  Curl.set_useragent c agent

let disconnect () =
  match !connection with
    | Some c ->
      connection := None;
      Curl.cleanup c;
      Curl.global_cleanup ()
    | _ -> ()

(* ************************************************************************** *)
(* Curl Get Page                                                              *)
(* ************************************************************************** *)

(* Return a text from a url using Curl and HTTP Auth                          *)
(* You must call "account" before calling this function                       *)
let get_text_form_url ?(html = false) url =
  match !connection with
    | None -> Error "Not connected"
    | Some c ->
      Buffer.clear result;
      try Success
	    (Curl.set_url c url;
	     if html
	     then Curl.set_httpheader c
	       ["Accept: application/vnd.github.VERSION.html+json"];
	     Curl.perform c;
	     Buffer.contents result)
      with
	| Curl.CurlException (_, _, _) -> Error !error_buffer
	| Failure msg -> Error msg
	| Invalid_argument msg -> Error msg
	| _ -> Error "Unexpected unknown error"

(* Take url, get page, apply function that takes a json tree, return result   *)
let go_json url f =
  match get_text_form_url url with
    | Error error -> Error error
    | Success str ->
      try Success (f (Yojson.Basic.from_string str))
      with
	| Yojson.Basic.Util.Type_error (msg, tree) ->
	  Error (msg ^ " " ^ (Yojson.Basic.to_string tree))
	| Yojson.Json_error msg -> Error msg
	| _ -> Error "Unexpected unknown error"

(* Take url, get page in html format and return it                            *)
let go_html url =
  get_text_form_url ~html:true url

(* ************************************************************************** *)
(* Get repositories                                                           *)
(* ************************************************************************** *)

type usertype = User | Organization

type repository =
    {
      owner       : string;
      name        : string;
      description : string;
      pushed_at   : string;
      git_url     : string;
      nb_issues   : int;
      url         : string;
      issues_url  : string;
    }

type repositories =
    {
      user_type : usertype;
      user_name : string;
      repos     : repository list;
    }

let usertype_tostring = function
  | User         -> "users"
  | Organization -> "orgs"

let get_repos ?(usertype = User) user =
  let url =
    base_url ^ (usertype_tostring usertype) ^ "/" ^
      user ^ "/repos?sort=updated&direction=desc" in
  let f tree =
    let repo tree =
      let name = tree |> member "name" |> to_string in
      {
	owner       = user;
	name        = name;
	description = tree |> member "description" |> to_string;
	pushed_at   = tree |> member "pushed_at"   |> to_string;
	git_url     = tree |> member "git_url"     |> to_string;
	nb_issues   = tree |> member "open_issues" |> to_int;
	url         = tree |> member "html_url"    |> to_string;
	issues_url  =
	  "https://github.com/" ^ user ^ "/" ^ name ^
	    "/issues?sort=created&state=open";
      } in
    let repos = List.map repo (tree |> to_list) in
    {
      user_type = usertype;
      user_name = user;
      repos     = repos;
    } in
  go_json url f

(* ************************************************************************** *)
(* Get Issues                                                                 *)
(* ************************************************************************** *)

type assignee =
    {
      a_name   : string;
      a_avatar : string;
    }

type label =
    {
      label_url   : string;
      label_name  : string;
      label_color : string;
    }

type issue =
    {
      title     : string;
      issue_url : string;
      assignee  : assignee option;
      labels    : label list;
    }

type issues =
    {
      user      : string;
      repo_name : string;
      html_url  : string;
      issues    : issue list;
    }

let get_issues user repo_name =
  let url =
    base_url ^ "repos/" ^ user ^ "/" ^
      repo_name ^ "/issues?state=open&sort=created&direction=asc" in
  let f tree =
    let issue tree =
      let get_assignee tree =
	match tree |> member "assignee" with
	  | `Null  -> None
	  | _ as a -> Some
	    {
	      a_name   = a |> member "login"      |> to_string;
	      a_avatar = a |> member "avatar_url" |> to_string;
	    }
      and get_labels =
	let to_label label =
	  {
	    label_url   = label |> member "url"   |> to_string;
	    label_name  = label |> member "name"  |> to_string;
	    label_color = label |> member "color" |> to_string;
	  } in
	List.map to_label in
      {
	title           = tree |> member "title"    |> to_string;
	issue_url       = tree |> member "html_url" |> to_string;
	assignee        = get_assignee tree;
	labels          = get_labels (tree |> member "labels" |> to_list);
      } in
    let issues = List.map issue (tree |> to_list) in
    {
      user      = user;
      repo_name = repo_name;
      html_url  =
	"https://github.com/" ^ user ^ "/" ^ repo_name ^
	  "/issues?sort=created&state=open";
      issues    = issues;
    } in
  go_json url f

let get_issues_from_repository repo =
  get_issues repo.owner repo.name

type organization_issues =
    {
      o_name       : string;
      o_issues_url : string;
      o_issues     : (repository * issues) list;
    }

let get_issues_from_organization org =
  match get_repos ~usertype:Organization org with
    | Error e -> Error e
    | Success repos ->
      let f repo =
	match get_issues_from_repository repo with
	  | Error e -> raise (Failure e)
	  | Success issues -> (repo, issues) in
      try
	Success {
	  o_name       = org;
	  o_issues_url =
	    "https://github.com/organizations/" ^ org ^
	      "/dashboard/issues/repos?direction=asc&sort=created&state=open";
	  o_issues     = List.map f repos.repos;
	}
      with Failure e -> Error e

(* ************************************************************************** *)
(* Get content of a repo                                                      *)
(* ************************************************************************** *)

let get_readme repo_owner repo_name =
  go_html (base_url ^ "repos/" ^ repo_owner ^ "/" ^ repo_name ^ "/readme")

let get_readme_from_repository repo = get_readme repo.owner repo.name
