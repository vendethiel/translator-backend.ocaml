open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type

type project_id = int [@@deriving yojson]

type project_object = {
  id : project_id;
  name : string;
} [@@deriving yojson]

type project_api = {
  name : string;
} [@@deriving yojson]


let to_project_object (id, name) =
  { id; name }

let list_projects =
  let query =
    let open Caqti_request.Infix in
    T.(unit ->* tup2 int string)
    "SELECT rowid, name FROM project" in
  fun (module Db : DB) ->
    let%lwt projects_or_error = Db.collect_list query () in
    let%lwt projects = Caqti_lwt.or_fail projects_or_error in
    Lwt.return @@ List.map to_project_object projects

let find_project =
  let query =
    let open Caqti_request.Infix in
    T.(int ->! tup2 int string)
    "SELECT rowid, name FROM project WHERE rowid = $1" in
  fun id (module Db : DB) ->
    let%lwt project_or_error = Db.find query id in
    let%lwt project = Caqti_lwt.or_fail project_or_error in
    Lwt.return @@ to_project_object project


let cors_middleware handler req =
  let handlers =
    [ "Allow", "OPTIONS, GET, HEAD, POST"
    ; "Access-Control-Allow-Origin", "*"
    ; "Access-Control-Allow-Methods", "OPTIONS, GET, HEAD, POST"
    ; "Access-Control-Allow-Headers", "Content-Type"
    ; "Access-Control-Max-Age", "86400"
    ]
  in
  let%lwt res = handler req in
  handlers
  |> List.iter (fun (key, value) -> Dream.add_header res key value);
  Lwt.return res


let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:db.sqlite"
  @@ cors_middleware
  @@ Dream.router [
    Dream.get "/projects" (fun request ->
      let%lwt projects = Dream.sql request list_projects in
      projects
      |> yojson_of_list yojson_of_project_object
      |> Yojson.Safe.to_string
      |> Dream.json);

    Dream.get "/projects/:id" (fun request ->
      let id_param = Dream.param request "id" in
      match int_of_string_opt id_param with
      | None ->
          Dream.empty `Bad_Request
      | Some id ->
          let%lwt project = Dream.sql request (find_project id) in
          project
          |> yojson_of_project_object
          |> Yojson.Safe.to_string
          |> Dream.json);

    Dream.post "/projects" (fun request ->
      let%lwt body = Dream.body request in
      let project_object =
        body
        |> Yojson.Safe.from_string
        |> project_object_of_yojson
      in
      project_object
      |> yojson_of_project_object
      |> Yojson.Safe.to_string
      |> Dream.json);
  ]
