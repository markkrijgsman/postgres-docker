-- Dummy data for our database dump, added here for reference.

create table example_table (
  id bigint not null,
  description character varying(255)
);

alter table only example_table add constraint example_table_pk unique (id);

insert into example_table (id, description) values (1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ');
insert into example_table (id, description) values (2, 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ');
insert into example_table (id, description) values (3, 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ');
insert into example_table (id, description) values (4, 'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.');
