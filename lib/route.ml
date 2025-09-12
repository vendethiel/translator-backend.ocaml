open Lwt.Syntax

let param n request = Some (Dream.param request n)

let param_int n request =
  let id_param = Dream.param request n in
  int_of_string_opt id_param

let run f h request =
  Option.value
    (Option.map (h request) @@ f request)
    ~default:(Dream.empty `Bad_Request)

let run_json f (h : 'a -> 'b -> Yojson.Safe.t Lwt.t) request =
  run f
    (fun req x ->
      let* res = h req x in
      res |> Yojson.Safe.to_string |> Dream.json)
    request

let json (f : 'a -> Yojson.Safe.t Lwt.t) request =
  let* res = f request in
  res |> Yojson.Safe.to_string |> Dream.json

let options f g o =
  match (f o, g o) with Some x, Some y -> Some (x, y) | _ -> None

(*
let compose g f x : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c = x |> f |> g
*)
