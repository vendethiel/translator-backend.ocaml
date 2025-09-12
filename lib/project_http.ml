open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Lwt.Syntax
open Route

let routes =
  [
    Dream.get "/projects"
    @@ json (fun request ->
           let+ projects = Dream.sql request Project_object.list in
           projects |> yojson_of_list Project_object.yojson_of_t);
    Dream.get "/projects/:id"
    @@ run_json (param_int "id") (fun request id ->
           let+ project = Dream.sql request (Project_object.find id) in
           project |> Project_object.yojson_of_t);
    (* TODO *)
    Dream.post "/projects" (fun request ->
        let* body = Dream.body request in
        let project_api =
          body |> Yojson.Safe.from_string |> Project_api.t_of_yojson
        in
        project_api |> Project_api.to_object 0 |> Project_object.yojson_of_t
        |> Yojson.Safe.to_string |> Dream.json);
  ]
