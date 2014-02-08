create table comments (
  id integer primary key,
  entry_id integer,
  name text,
  body text,
  allow integer default 0 check (allow in (0, 1)),
  created_at
);