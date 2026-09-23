-- 003_actor.sql
-- Actors are the things that DO: they hold memberships, form relations and
-- take part in events. Individuals and organizations behave identically in
-- all three, so they share one supertype and the relation tables point here.
-- Places do not act — they are acted upon — so they stay out of this.

BEGIN;

-- org_type needs the same composite key place_type got in 002
ALTER TABLE org_type
    ADD CONSTRAINT org_type_id_world_uniq UNIQUE (id, world_id);

CREATE TABLE actor (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id    bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    actor_kind  text   NOT NULL CHECK (actor_kind IN ('individual','org')),
    name        text   NOT NULL,
    description text,
    attributes  jsonb  NOT NULL DEFAULT '{}',

    -- lets a subtype pin the kind it is allowed to be
    UNIQUE (id, actor_kind),
    -- lets a subtype prove it stayed inside one world
    UNIQUE (id, world_id)
);

-- A person, a god, a dragon, an AI core — anything that acts alone.
CREATE TABLE individual (
    actor_id   bigint PRIMARY KEY,
    actor_kind text NOT NULL DEFAULT 'individual'
               CHECK (actor_kind = 'individual'),

    FOREIGN KEY (actor_id, actor_kind) REFERENCES actor (id, actor_kind)
        ON DELETE CASCADE
);

-- A kingdom, a house, a guild, a corporation, a fleet.
CREATE TABLE org (
    actor_id      bigint PRIMARY KEY,
    actor_kind    text   NOT NULL DEFAULT 'org' CHECK (actor_kind = 'org'),
    world_id      bigint NOT NULL,
    org_type_id   bigint NOT NULL,
    parent_org_id bigint,

    UNIQUE (actor_id, world_id),

    FOREIGN KEY (actor_id, actor_kind) REFERENCES actor (id, actor_kind)
        ON DELETE CASCADE,
    FOREIGN KEY (actor_id, world_id)   REFERENCES actor (id, world_id),
    FOREIGN KEY (org_type_id, world_id)
        REFERENCES org_type (id, world_id) ON DELETE RESTRICT,
    FOREIGN KEY (parent_org_id, world_id)
        REFERENCES org (actor_id, world_id) ON DELETE SET NULL,

    CONSTRAINT org_not_own_parent CHECK (parent_org_id IS DISTINCT FROM actor_id)
);

CREATE INDEX ON actor (world_id);
CREATE INDEX ON actor USING gin (attributes);
CREATE INDEX ON org (parent_org_id);
CREATE INDEX ON org (org_type_id);

-- Joining the supertype every time is tedious; hide it behind views.
CREATE VIEW v_individual AS
SELECT a.id, a.world_id, a.name, a.description, a.attributes
FROM actor a JOIN individual i ON i.actor_id = a.id;

CREATE VIEW v_org AS
SELECT a.id, a.world_id, a.name, a.description, a.attributes,
       o.org_type_id, o.parent_org_id
FROM actor a JOIN org o ON o.actor_id = a.id;

COMMIT;
