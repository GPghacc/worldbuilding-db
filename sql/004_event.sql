-- 004_event.sql
-- Events are the time anchor. Anything that starts or ends points at an event,
-- so "what was true at moment X" becomes a comparison of positions.
-- year and chapter are optional labels for humans; seq is the one order
-- the queries trust.

BEGIN;

CREATE TABLE event (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    world_id   bigint  NOT NULL REFERENCES world(id) ON DELETE CASCADE,
    seq        numeric NOT NULL,   -- canonical order; 1.5 fits between 1 and 2
    name       text    NOT NULL,
    year       int,                -- label: in-world year, if the author uses one
    chapter    text,               -- label: '3장', '2권 5화', if that's the habit
    place_id   bigint,
    summary    text,
    attributes jsonb   NOT NULL DEFAULT '{}',

    UNIQUE (id, world_id),
    FOREIGN KEY (place_id, world_id)
        REFERENCES place (id, world_id) ON DELETE SET NULL (place_id)
);

CREATE INDEX ON event (world_id, seq);
CREATE INDEX ON event (place_id);

-- Births and deaths hang on events of the same world.
ALTER TABLE individual
    ADD COLUMN born_event bigint,
    ADD COLUMN died_event bigint,
    ADD FOREIGN KEY (born_event, world_id)
        REFERENCES event (id, world_id) ON DELETE SET NULL (born_event),
    ADD FOREIGN KEY (died_event, world_id)
        REFERENCES event (id, world_id) ON DELETE SET NULL (died_event);

CREATE INDEX ON individual (born_event);
CREATE INDEX ON individual (died_event);

COMMIT;
