create table project (
  name text
);

create table task (
  project_id int references project (rowid),
  name text not null,
  translations text not null -- jsonb in postgresql
);
