(* ************************************************************************** *)
(* Project: GitHub API v3 bindings in OCaml                                   *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version on GitHub: https://github.com/db0company/GitHub-API-OCaml   *)
(* ************************************************************************** *)
(** GitHub API v3 bindings in OCaml                                           *)

(** Return values type                                                        *)
type 'a t = Success of 'a | Error of string

(* ************************************************************************** *)
(* {3 Requirements}                                                           *)
(* ************************************************************************** *)

(** Connect to the API using your username and password on GitHub.            *)
val connect : ?agent:string -> string -> string -> unit

val disconnect: unit -> unit

(* ************************************************************************** *)
(* {3 Get repositories}                                                       *)
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

val get_repos : ?usertype : usertype -> string -> repositories t

(* ************************************************************************** *)
(** {3 Get Issues}                                                            *)
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

val get_issues : string -> string -> issues t
val get_issues_from_repository : repository -> issues t

type organization_issues =
    {
      o_name       : string;
      o_issues_url : string;
      o_issues     : (repository * issues) list;
    }

val get_issues_from_organization : string -> organization_issues t

(* ************************************************************************** *)
(** {3 Get content of a repo}                                                 *)
(* ************************************************************************** *)

val get_readme : string -> string -> string t
val get_readme_from_repository : repository -> string t
