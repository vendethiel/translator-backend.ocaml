open Ppx_yojson_conv_lib.Yojson_conv.Primitives
open Lwt.Syntax
open Route

let routes =
  [
    Dream.get "/projects/:project_id/tasks"
    @@ run_json (param_int "project_id") (fun request project_id ->
           let+ tasks = Dream.sql request (Task_object.list project_id) in
           tasks |> yojson_of_list Task_object.yojson_of_t);
    Dream.get "/projects/:project_id/tasks/:id"
    @@ run_json
         (options (param_int "project_id") (param_int "id"))
         (fun request (project_id, id) ->
           let+ task = Dream.sql request (Task_object.find project_id id) in
           task |> Task_object.yojson_of_t);
    Dream.post "/projects/:project_id/tasks/:id/lang/:lang"
    @@ run_json
         (options (param_int "project_id")
            (options (param_int "id") (param "lang")))
         (fun request (project_id, (id, lang_key)) ->
           let* value = Dream.body request in
           let* () =
             Dream.sql request (Task_object.translate id lang_key value)
           in
           let+ task = Dream.sql request (Task_object.find project_id id) in
           task |> Task_object.yojson_of_t);
  ]
