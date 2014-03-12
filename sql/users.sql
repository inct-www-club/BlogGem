create table users (
    id text primary key not null,
    name text unique not null,
    password_hash text not null,
    password_salt text not null
);
