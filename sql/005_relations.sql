-- 005_relations.sql
-- The four relations that make this more than an address book.
-- Every one of them can start and end at an event, so each row is a fact
-- that was true for a stretch of the story, not just "true now".
--
-- Time rule used by every query:
--   a row holds at event E  when  start.seq <= E.seq  AND  (no end OR E.seq < end.seq)
--   start_event NULL = "since before the record begins"
--   end_event   NULL = "still true"

BEGIN;

-- Same composite keys the other vocabulary tables already got
ALTER TABLE relation_type
    ADD CONSTRAINT relation_type_id_world_uniq UNIQUE (id, world_id);
ALTER TABLE role_type
    ADD CONSTRAINT role_type_id_world_uniq UNIQUE (id, world_id);


-- 1. Who belongs to which organization, in what role, and when.
--    member is any actor, so a house can join an alliance too.
CREATE TABLE membership (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id     bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    member_id    bigint NOT NULL,
    org_id       bigint NOT NULL,
    role_type_id bigint,
    start_event  bigint,
    end_event    bigint,
    note         text,

    FOREIGN KEY (member_id, world_id)    REFERENCES actor (id, world_id)       ON DELETE CASCADE,
    FOREIGN KEY (org_id, world_id)       REFERENCES org (actor_id, world_id)   ON DELETE CASCADE,
    FOREIGN KEY (role_type_id, world_id) REFERENCES role_type (id, world_id)   ON DELETE SET NULL (role_type_id),
    FOREIGN KEY (start_event, world_id)  REFERENCES event (id, world_id)       ON DELETE RESTRICT,
    FOREIGN KEY (end_event, world_id)    REFERENCES event (id, world_id)       ON DELETE RESTRICT,

    CONSTRAINT membership_not_self CHECK (member_id <> org_id),
    CONSTRAINT membership_span     CHECK (start_event IS NULL OR end_event IS NULL OR start_event <> end_event)
);


-- 2. Any actor to any actor: allied, at war, sworn to, betrayed, rival ...
--    Symmetric types are stored once; v_actor_relation shows both directions.
CREATE TABLE actor_relation (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id         bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    from_actor       bigint NOT NULL,
    to_actor         bigint NOT NULL,
    relation_type_id bigint NOT NULL,
    start_event      bigint,
    end_event        bigint,
    note             text,

    FOREIGN KEY (from_actor, world_id)       REFERENCES actor (id, world_id)         ON DELETE CASCADE,
    FOREIGN KEY (to_actor, world_id)         REFERENCES actor (id, world_id)         ON DELETE CASCADE,
    FOREIGN KEY (relation_type_id, world_id) REFERENCES relation_type (id, world_id) ON DELETE RESTRICT,
    FOREIGN KEY (start_event, world_id)      REFERENCES event (id, world_id)         ON DELETE RESTRICT,
    FOREIGN KEY (end_event, world_id)        REFERENCES event (id, world_id)         ON DELETE RESTRICT,

    CONSTRAINT relation_not_self CHECK (from_actor <> to_actor),
    CONSTRAINT relation_span     CHECK (start_event IS NULL OR end_event IS NULL OR start_event <> end_event)
);


-- 3. Who holds which place, and when. Any actor: a kingdom, or one dragon.
CREATE TABLE control (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id    bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    actor_id    bigint NOT NULL,
    place_id    bigint NOT NULL,
    start_event bigint,
    end_event   bigint,
    note        text,

    FOREIGN KEY (actor_id, world_id)    REFERENCES actor (id, world_id) ON DELETE CASCADE,
    FOREIGN KEY (place_id, world_id)    REFERENCES place (id, world_id) ON DELETE CASCADE,
    FOREIGN KEY (start_event, world_id) REFERENCES event (id, world_id) ON DELETE RESTRICT,
    FOREIGN KEY (end_event, world_id)   REFERENCES event (id, world_id) ON DELETE RESTRICT,

    CONSTRAINT control_span CHECK (start_event IS NULL OR end_event IS NULL OR start_event <> end_event)
);


-- 4. Who took part in an event, and as what ('attacker', 'fell', 'witness' ...).
CREATE TABLE event_participant (
    event_id bigint NOT NULL,
    actor_id bigint NOT NULL,
    world_id bigint NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    role     text,

    PRIMARY KEY (event_id, actor_id),
    FOREIGN KEY (event_id, world_id) REFERENCES event (id, world_id) ON DELETE CASCADE,
    FOREIGN KEY (actor_id, world_id) REFERENCES actor (id, world_id) ON DELETE CASCADE
);


-- Foreign keys do not get indexes automatically; relation tables are joined constantly.
CREATE INDEX ON membership (member_id);
CREATE INDEX ON membership (org_id);
CREATE INDEX ON membership (role_type_id);
CREATE INDEX ON membership (start_event);
CREATE INDEX ON membership (end_event);

CREATE INDEX ON actor_relation (from_actor);
CREATE INDEX ON actor_relation (to_actor);
CREATE INDEX ON actor_relation (relation_type_id);
CREATE INDEX ON actor_relation (start_event);
CREATE INDEX ON actor_relation (end_event);

CREATE INDEX ON control (actor_id);
CREATE INDEX ON control (place_id);
CREATE INDEX ON control (start_event);
CREATE INDEX ON control (end_event);

CREATE INDEX ON event_participant (actor_id);


-- Every relation seen from both ends. A symmetric type reads the same both
-- ways; a directed one uses its inverse_name from the other side.
CREATE VIEW v_actor_relation AS
SELECT r.id, r.world_id,
       r.from_actor AS actor_id, r.to_actor AS other_id,
       rt.name      AS relation,
       r.start_event, r.end_event
FROM actor_relation r
JOIN relation_type rt ON rt.id = r.relation_type_id
UNION ALL
SELECT r.id, r.world_id,
       r.to_actor, r.from_actor,
       CASE WHEN rt.is_symmetric THEN rt.name
            ELSE coalesce(rt.inverse_name, '← ' || rt.name) END,
       r.start_event, r.end_event
FROM actor_relation r
JOIN relation_type rt ON rt.id = r.relation_type_id;

COMMIT;
