-- 002_place.sql
-- Places form a tree of containment. Depth is not fixed: each world nests
-- as deeply as it needs (continent > realm > holding > village, or
-- system > planet > city > district).

BEGIN;

-- Prerequisite: lets other tables prove a type comes from the SAME world.
-- (Fold this into 001 later if you prefer; kept here so each file is explicit.)
ALTER TABLE place_type
    ADD CONSTRAINT place_type_id_world_uniq UNIQUE (id, world_id);

CREATE TABLE place (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id      bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    place_type_id bigint NOT NULL,
    parent_id     bigint,
    name          text   NOT NULL,
    description   text,
    attributes    jsonb  NOT NULL DEFAULT '{}',

    -- a child must prove it lives in the same world as its parent
    UNIQUE (id, world_id),
    FOREIGN KEY (parent_id, world_id)
        REFERENCES place (id, world_id) ON DELETE CASCADE,

    -- the type must belong to this world's vocabulary
    FOREIGN KEY (place_type_id, world_id)
        REFERENCES place_type (id, world_id) ON DELETE RESTRICT,

    -- a place cannot contain itself (deeper cycles are a known limitation)
    CONSTRAINT place_not_own_parent CHECK (parent_id IS DISTINCT FROM id),

    -- siblings cannot share a name; NULLS NOT DISTINCT so two roots collide too
    UNIQUE NULLS NOT DISTINCT (world_id, parent_id, name)
);

CREATE INDEX ON place (world_id);
CREATE INDEX ON place (parent_id);
CREATE INDEX ON place (place_type_id);
CREATE INDEX ON place USING gin (attributes);

COMMIT;
