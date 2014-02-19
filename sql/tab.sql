create table tabs (
    id integer primary key,
    label text,
    address text,
    child_id text,
    have_parent integer default 0 check (have_parent in (0, 1))
);