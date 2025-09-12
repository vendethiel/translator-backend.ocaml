create table organization (
  name text
);

create table user (
  email text not null,
  password text not null,
  token text not null,
  current_organization int
    references organization (rowid)
);

create table organization_user (
  organization_id int not null
    references organization (rowid),
  user_id int not null
    references user (rowid),
  primary key (organization_id, user_id)
);

create table project (
  organization_id int not null
    references organization (rowid),
  name text not null
);

create table task (
  project_id int not null
    references project (rowid),
  name text not null,
  translations text not null -- jsonb in postgresql
);
