let cors_middleware handler req =
  let headers =
    [
      ("Allow", "OPTIONS, GET, HEAD, POST");
      ("Access-Control-Allow-Origin", "*");
      ("Access-Control-Allow-Methods", "OPTIONS, GET, HEAD, POST");
      ("Access-Control-Allow-Headers", "Content-Type");
      ("Access-Control-Max-Age", "86400");
    ]
  in
  let%lwt res = handler req in
  headers |> List.iter (fun (key, value) -> Dream.add_header res key value);
  Lwt.return res

let user_field : User_object.t Dream.field = Dream.new_field ~name:"user" ()

exception UserTokenMissing
(* exception UserNotFound *)

let login_middleware handler req =
  let user_token =
    match Dream.header req "X-USER-TOKEN" with
    | Some token -> token
    | None -> raise UserTokenMissing
  in
  let%lwt user = Dream.sql req (User_object.by_token user_token) in
  Dream.set_field req user_field user;
  handler req
