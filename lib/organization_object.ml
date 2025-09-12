open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION

module T = Caqti_type

type id = int [@@deriving yojson]
type t = { id : id; name : string } [@@deriving yojson]

let from_tuple (id, name) = { id; name }

let user_organization =
  let query =
    let open Caqti_request.Infix in
    T.(int ->! tup2 int string)
      "SELECT o.rowid, o.name\n\
       FROM organization o\n\
       WHERE EXISTS (\n\
      \  SELECT 1\n\
      \  FROM organization_user ou\n\
      \  WHERE ou.organization_id = o.rowid\n\
      \    AND ou.user_id = $1\n\
       )"
  in
  fun user_id (module Db : DB) ->
    let%lwt orgs_or_error = Db.collect_list query user_id in
    Lwt.map (List.map from_tuple) @@ Caqti_lwt.or_fail orgs_or_error
