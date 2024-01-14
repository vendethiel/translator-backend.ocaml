open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type
type id = int [@@deriving yojson]

type translations = (string * string) list [@@deriving yojson]

type t = {
  id : id;
  project_id : Project_object.id [@key "projectId"];
  name : string;
  translations : translations;
} [@@deriving yojson]

let from_tuple (id, project_id, name, translations) =
  { id; project_id; name; translations = translations |> Yojson.Safe.from_string |> translations_of_yojson  }

let list =
  let query =
    let open Caqti_request.Infix in
    T.(int ->* tup4 int int string string)
    "SELECT rowid, project_id, name, translations FROM task WHERE project_id = $1" in
  fun project_id (module Db : DB) ->
    let%lwt tasks_or_error = Db.collect_list query project_id in
    Lwt.map (List.map from_tuple) @@ Caqti_lwt.or_fail tasks_or_error
