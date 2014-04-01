create table entries (
    id integer primary key,
    title text,
    thumbnail text,
    body text,
    category text,
    comment_num integer default 0 check (comment_num >= 0),
    created_at,
    updated_at
);
