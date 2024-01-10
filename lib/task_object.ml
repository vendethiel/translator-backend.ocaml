open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type

type id = int [@@deriving yojson]

type t = {
  id : id;
  project_id : Project_object.id;
  key : string;
} [@@deriving yojson]

let from_tuple (id, project_id, key) =
  { id; project_id; key }

let list =
  let query =
    let open Caqti_request.Infix in
    T.(int ->* tup3 int int string)
    "SELECT rowid, project_id, key FROM task WHERE project_id = $1" in
  fun project_id (module Db : DB) ->
    let%lwt tasks_or_error = Db.collect_list query project_id in
    Lwt.map (List.map from_tuple) @@ Caqti_lwt.or_fail tasks_or_error