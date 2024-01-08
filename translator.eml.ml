open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type

module ProjectObject = struct
  type id = int [@@deriving yojson]

  type t = {
    id : id;
    name : string;
  } [@@deriving yojson]

  let from_tuple (id, name) =
    { id; name }
end

module ProjectApi = struct
  type t = {
    name : string;
  } [@@deriving yojson]

  let to_object id { name } = ProjectObject.from_tuple (id, name)
end

module TaskObject = struct
  type id = int [@@deriving yojson]

  type t = {
    id : id;
    project_id : ProjectObject.id;
    key : string;
  } [@@deriving yojson]

  let from_tuple (id, project_id, key) =
    { id; project_id; key }
end

let list_projects =
  let query =
    let open Caqti_request.Infix in
    T.(unit ->* tup2 int string)
    "SELECT rowid, name FROM project" in
  fun (module Db : DB) ->
    let%lwt projects_or_error = Db.collect_list query () in
    let%lwt projects = Caqti_lwt.or_fail projects_or_error in
    Lwt.return @@ List.map ProjectObject.from_tuple projects

let find_project =
  let query =
    let open Caqti_request.Infix in
    T.(int ->! tup2 int string)
    "SELECT rowid, name FROM project WHERE rowid = $1" in
  fun id (module Db : DB) ->
    let%lwt project_or_error = Db.find query id in
    let%lwt project = Caqti_lwt.or_fail project_or_error in
    Lwt.return @@ ProjectObject.from_tuple project

let list_tasks =
  let query =
    let open Caqti_request.Infix in
    T.(int ->* tup3 int int string)
    "SELECT rowid, project_id, key FROM task WHERE project_id = $1" in
  fun project_id (module Db : DB) ->
    let%lwt tasks_or_error = Db.collect_list query project_id in
    let%lwt tasks = Caqti_lwt.or_fail tasks_or_error in
    Lwt.return @@ List.map TaskObject.from_tuple tasks

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
      |> yojson_of_list ProjectObject.yojson_of_t
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
          |> ProjectObject.yojson_of_t
          |> Yojson.Safe.to_string
          |> Dream.json);

    Dream.post "/projects" (fun request ->
      let%lwt body = Dream.body request in
      let project_api =
        body
        |> Yojson.Safe.from_string
        |> ProjectApi.t_of_yojson
      in
      project_api
      |> ProjectApi.to_object 0
      |> ProjectObject.yojson_of_t
      |> Yojson.Safe.to_string
      |> Dream.json);
  ]
