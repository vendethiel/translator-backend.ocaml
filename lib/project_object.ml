open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION
module T = Caqti_type

type id = int [@@deriving yojson]

type t = {
  id : id;
  name : string;
} [@@deriving yojson]

let from_tuple (id, name) =
  { id; name }

let list =
  let query =
    let open Caqti_request.Infix in
    T.(unit ->* tup2 int string)
    "SELECT rowid, name FROM project" in
  fun (module Db : DB) ->
    let%lwt projects_or_error = Db.collect_list query () in
    Lwt.map (List.map from_tuple) @@ Caqti_lwt.or_fail projects_or_error

let find =
  let query =
    let open Caqti_request.Infix in
    T.(int ->! tup2 int string)
    "SELECT rowid, name FROM project WHERE rowid = $1" in
  fun id (module Db : DB) ->
    let%lwt project_or_error = Db.find query id in
    Lwt.map from_tuple @@ Caqti_lwt.or_fail project_or_error
