-- 001_world.sql
-- Worlds and their per-world vocabulary.
-- Types are data, not enums: each world defines its own terms, so the same
-- schema holds high fantasy, space opera or a modern thriller.

BEGIN;

CREATE TABLE world (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text        NOT NULL,
    description text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- continent / kingdom / city ... or system / planet / district
CREATE TABLE place_type (
    id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    name     text   NOT NULL,
    depth_hint int,                    -- optional: 1 = broadest
    UNIQUE (world_id, name)
);

-- kingdom / house / guild ... or corporation / fleet / party
CREATE TABLE org_type (
    id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    name     text   NOT NULL,
    UNIQUE (world_id, name)
);

-- allied / at war / sworn to / rival ...
CREATE TABLE relation_type (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id     bigint  NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    name         text    NOT NULL,
    is_symmetric boolean NOT NULL DEFAULT false,
    inverse_name text,                 -- 'sworn to' <-> 'liege of'
    UNIQUE (world_id, name),
    CONSTRAINT symmetric_has_no_inverse
        CHECK (NOT is_symmetric OR inverse_name IS NULL)
);

-- king / knight / master ... or captain / director
CREATE TABLE role_type (
    id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    name     text   NOT NULL,
    UNIQUE (world_id, name)
);

CREATE INDEX ON place_type    (world_id);
CREATE INDEX ON org_type      (world_id);
CREATE INDEX ON relation_type (world_id);
CREATE INDEX ON role_type     (world_id);

COMMIT;
