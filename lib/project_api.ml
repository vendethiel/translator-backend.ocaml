open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type t = {
  name : string;
} [@@deriving yojson]

let to_object id { name } = Project_object.from_tuple (id, name)