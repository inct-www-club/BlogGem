create table tabs (
    id integer primary key,
    label text,
    address text,
    parent_id integer default null check (parent_id > 0 || parent_id == null)
);