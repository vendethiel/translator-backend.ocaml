open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module type DB = Caqti_lwt.CONNECTION

module T = Caqti_type

type id = int [@@deriving yojson]
type t = { id : id; email : string; token : string } [@@deriving yojson]

let from_tuple (id, email, token) = { id; email; token }

let by_token =
  let query =
    let open Caqti_request.Infix in
    T.(string ->! tup3 int string string)
      "SELECT rowid, email, token FROM user WHERE token = $1"
  in
  fun token (module Db : DB) ->
    let%lwt user_or_error = Db.find query token in
    Lwt.map from_tuple @@ Caqti_lwt.or_fail user_or_error
