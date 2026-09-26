-- 000_reset.sql
-- Development only: wipe everything and rebuild from 001 onward.
DROP VIEW IF EXISTS v_actor_relation, v_org, v_individual;

DROP TABLE IF EXISTS
    event_participant, control, actor_relation, membership,
    org, individual, actor, event, place,
    role_type, relation_type, org_type, place_type, world
CASCADE;
