open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type
type id = int [@@deriving yojson]

exception WrongTranslationFormat of string

module Translations = struct
  include Map.Make(String)
  type map = string t

  let yojson_of_map xs = `Assoc (List.map (function (k, v) -> (k, `String v)) @@ bindings xs)
  let map_of_yojson = function
  | `Assoc xs -> of_list @@ List.map (function
    | k, `String v -> (k, v)
    | _ -> raise @@ WrongTranslationFormat "Expected a string value") xs
  | _ -> raise @@ WrongTranslationFormat "Expected an assoc"
end

type t = {
  id : id;
  project_id : Project_object.id [@key "projectId"];
  name : string;
  translations : Translations.map;
} [@@deriving yojson]

let from_tuple (id, project_id, name, translations) =
  { id; project_id; name; translations = translations |> Yojson.Safe.from_string |> Translations.map_of_yojson  }

let list =
  let query =
    let open Caqti_request.Infix in
    T.(int ->* tup4 int int string string)
    "SELECT rowid, project_id, name, translations FROM task WHERE project_id = $1" in
  fun project_id (module Db : DB) ->
    let%lwt tasks_or_error = Db.collect_list query project_id in
    Lwt.map (List.map from_tuple) @@ Caqti_lwt.or_fail tasks_or_error

let find =
  let query =
    let open Caqti_request.Infix in
    T.(tup2 int int ->! tup4 int int string string)
    "SELECT rowid, project_id, name, translations FROM task WHERE project_id = $1 AND rowid = $2" in
  fun project_id id (module Db : DB) ->
    let%lwt task_or_error = Db.find query (project_id, id) in
    Lwt.map from_tuple @@ Caqti_lwt.or_fail task_or_error

let translate =
  let query =
    let open Caqti_request.Infix in
    T.(tup3 string string int ->. unit)
    (* we'll have to make sure the key is a simple key and can't be tore down further *)
    "UPDATE task SET translations = json_set(translations, '$.' || $1, $2) WHERE rowid = $3" in
  fun task_id lang_code translation (module Db : DB) ->
    let%lwt result = Db.exec query (task_id, lang_code, translation) in
    Caqti_lwt.or_fail result
