(* ************************************************************************** *)
(* Project: GitHub API v3 bindings in OCaml                                   *)
(* Author: db0 (db0company@gmail.com, http://db0.fr/)                         *)
(* Latest Version on GitHub: https://github.com/db0company/GitHub-API-OCaml   *)
(* ************************************************************************** *)

let (username, password) =
  try (Sys.argv.(1), Sys.argv.(2))
  with _ ->
    prerr_endline ("Usage: " ^ Sys.argv.(0) ^ " username password");
    exit 1

let _ =

  Github.connect username password;

  match Github.get_repos username with
    | Github.Error error   -> prerr_endline ("[Error] " ^ error)
    | Github.Success repos ->

      print_endline (repos.Github.user_name ^ "'s repositories:");

      let print_repo repo =
	print_endline repo.Github.name;
	print_endline ("  " ^ repo.Github.description) in

      List.iter print_repo repos.Github.repos;

      match repos.Github.repos with
	| [] -> ()
	| first_repo::rest ->

	  match Github.get_readme_from_repository first_repo with
	    | Github.Error error    -> prerr_endline ("[Error] " ^ error)
	    | Github.Success readme ->

	      print_endline "README of the 1st repo:";
	      print_endline readme
