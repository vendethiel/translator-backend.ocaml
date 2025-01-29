let start_server () =
  Dream.run @@ Dream.logger
  @@ Dream.sql_pool "sqlite3:db.sqlite"
  @@ Middleware.cors_middleware
  @@ Dream.router
       [
         (*TODO login middleware*)
         Dream.scope "/projects"
           [ Middleware.login_middleware ]
           [
             Dream.scope "/" [] Project_http.routes;
             Dream.scope "/:project_id/tasks" [] Task_http.routes;
           ];
       ]
