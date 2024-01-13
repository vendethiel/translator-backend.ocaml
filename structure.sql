create table project (
  name text
);

create table task (
  project_id references project (rowid),
  key text not null,
  translations not null jsonb
);