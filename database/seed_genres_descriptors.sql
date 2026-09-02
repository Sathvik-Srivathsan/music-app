-- =============================================================================
-- SUPABASE SEED: genres + descriptors (lists and full trees)
-- =============================================================================
-- This file is a READ-ONLY documentation / reference seed generated directly
-- from the LIVE Supabase database. It is NOT meant to be re-run against the
-- live database (the data is already there and this is not idempotent by id).
--
-- Purpose: a fully self-contained snapshot of the genre + descriptor data so
-- anyone reading the repository can understand the exact contents and full
-- parent->child tree structure that exists on Supabase today.
--
-- WHAT IS INCLUDED
--   * genres      : the complete genre node list (id + name + the three
--                   derived counters).
--   * genre_hierarchy      : every single parent->child edge of the genre tree.
--   * descriptors          : the complete descriptor node list (same columns).
--   * descriptor_hierarchy : every single parent->child edge of the descriptor
--                            tree.
--
-- WHAT IS NOT INCLUDED
--   * artists     - artists are created live by the app on record insert; they
--                   are NOT part of this seed (explicit requirement).
--   * records, record_artists, record_genres, record_descriptors,
--     record_streaming, audit_log - app runtime data, not seed data.
--
-- NOTE ON IDS
--   Foreign keys reference genre_id / descriptor_id by integer id. The live
--   values are preserved so the edges resolve exactly as they do on Supabase.
--   The name comments beside each edge make the tree human-readable.
-- =============================================================================


-- =============================================================================
-- COUNT COLUMN ALGORITHMS (ref_count / children_count / total_ref_count)
-- =============================================================================
-- The three numeric columns on artists/genres/descriptors are DENORMALIZED for
-- fast UI display. They are maintained automatically by DB triggers whenever
-- record-link rows or hierarchy edges change. Their exact semantics:
--
-- 1) ref_count  (direct reference count)
--      Number of RECORDS that DIRECTLY reference this node.
--      genres:      SELECT COUNT(*) FROM record_genres  WHERE genre_id = X
--      descriptors: SELECT COUNT(*) FROM record_descriptors WHERE descriptor_id = X
--      artists:     SELECT COUNT(*) FROM record_artists WHERE artist_id = X
--      Incremented/decremented by fn_record_genres_ref_count(),
--      fn_record_descriptors_ref_count(), fn_record_artists_ref_count()
--      AFTER INSERT/DELETE on the record_* junction tables.
--
-- 2) children_count  (number of descendant nodes below this node)
--      Number of nodes in this node's ENTIRE subtree (all recursive
--      descendants), regardless of depth. Computed with the recursive
--      ancestor/descendant traversal:
--          get_genre_ancestors / get_descriptor_ancestors
--      On add of a parent->child edge: for the new child's parent AND every
--      ancestor of that parent, children_count += 1 (the new child now sits
--      under all of them). On edge removal the same loop subtracts. Maintained
--      by fn_genre_hierarchy_children() / fn_descriptor_hierarchy_children()
--      AFTER INSERT/DELETE on genre_hierarchy / descriptor_hierarchy.
--
-- 3) total_ref_count  (inherited reference count)
--      Number of RECORDS that reference this node OR any node in its subtree
--      (i.e. every record that "counts" for this node once inheritance is
--      rolled up). A record tagged with a descendant genre also counts toward
--      every ancestor genre.
--      Implemented by walking UP from each tagged node: when a
--      record_genres/record_descriptors link is inserted, every ancestor of the
--      tagged node (plus the node itself) gets total_ref_count += 1.
--      Maintained by fn_record_genres_refs() / fn_record_descriptors_refs()
--      AFTER INSERT/DELETE on record_genres / record_descriptors.
--
-- The full DDL for these functions/triggers lives in schema.sql.
-- =============================================================================


-- =============================================================================
-- 1. GENRE NODES (genres)
-- =============================================================================
-- Complete live node list. genre_id values are preserved so the tree edges
-- below resolve exactly as they do on Supabase.
BEGIN;

INSERT INTO public.genres (genre_id, genre_name, ref_count, children_count, total_ref_count) VALUES
  (1, '''Ote''a', 0, 0, 0), -- LEAF
  (2, '16-bit', 0, 0, 0), -- LEAF
  (3, '2 Tone', 1, 0, 1), -- LEAF
  (4, '2-Step', 3, 0, 3), -- LEAF
  (5, '3-Step', 0, 0, 0), -- LEAF
  (6, 'A cappella', 6, 8, 6), -- 8 children
  (7, 'Aak', 0, 0, 0), -- LEAF
  (8, 'Abakuá Music', 0, 0, 0), -- LEAF
  (9, 'Abkhazian Folk Music', 0, 0, 0), -- LEAF
  (10, 'Aboio', 0, 1, 0), -- 1 children
  (11, 'Aboio cantado', 0, 0, 0), -- LEAF
  (12, 'Abstract Hip Hop', 85, 0, 85), -- LEAF
  (13, 'Acholi Music', 0, 1, 0), -- 1 children
  (14, 'Acholitronix', 0, 0, 0), -- LEAF
  (15, 'Achomi Music', 0, 0, 0), -- LEAF
  (16, 'Acid Breaks', 7, 0, 7), -- LEAF
  (17, 'Acid House', 1, 0, 1), -- LEAF
  (18, 'Acid Jazz', 3, 0, 3), -- LEAF
  (19, 'Acid Rock', 5, 0, 5), -- LEAF
  (20, 'Acid Techno', 4, 0, 4), -- LEAF
  (21, 'Acid Trance', 2, 0, 2), -- LEAF
  (22, 'Acidcore', 1, 0, 1), -- LEAF
  (23, 'Acousmatic Music', 0, 0, 0), -- LEAF
  (24, 'Acoustic Blues', 0, 4, 0), -- 4 children
  (25, 'Acoustic Chicago Blues', 0, 0, 0), -- LEAF
  (26, 'Acoustic Rock', 0, 0, 0), -- LEAF
  (27, 'Acoustic Texas Blues', 0, 0, 0), -- LEAF
  (28, 'Adhunik geet', 0, 0, 0), -- LEAF
  (29, 'Adult Contemporary', 0, 0, 0), -- LEAF
  (30, 'Aegean Islands Folk Music', 0, 0, 0), -- LEAF
  (31, 'Afar Music', 0, 0, 0), -- LEAF
  (32, 'Afoxé', 0, 0, 0), -- LEAF
  (33, 'African Folk Music', 2, 22, 2), -- 22 children
  (34, 'African Music', 0, 208, 7), -- 208 children
  (35, 'Afrikaner Folk Music', 0, 0, 0), -- LEAF
  (36, 'Afro House', 0, 1, 0), -- 1 children
  (37, 'Afro Trap', 0, 0, 0), -- LEAF
  (38, 'Afro-Cuban Jazz', 0, 0, 0), -- LEAF
  (39, 'Afro-Funk', 0, 0, 0), -- LEAF
  (40, 'Afro-Jazz', 1, 0, 1), -- LEAF
  (41, 'Afro-Rock', 0, 0, 0), -- LEAF
  (42, 'Afrobeat', 2, 0, 2), -- LEAF
  (43, 'Afrobeats', 0, 2, 0), -- 2 children
  (44, 'Afrofuturism', 0, 0, 0), -- LEAF
  (45, 'Afropiano', 0, 0, 0), -- LEAF
  (46, 'Afroswing', 0, 0, 0), -- LEAF
  (47, 'Agbadza', 0, 0, 0), -- LEAF
  (48, 'Agbekor', 0, 0, 0), -- LEAF
  (49, 'Aggrotech', 1, 0, 1), -- LEAF
  (50, 'Agronejo', 0, 0, 0), -- LEAF
  (51, 'Ahwash', 0, 0, 0), -- LEAF
  (52, 'Ainu Music', 0, 2, 0), -- 2 children
  (53, 'Aita', 0, 0, 0), -- LEAF
  (54, 'Akan Music', 0, 2, 0), -- 2 children
  (55, 'Akishibu-kei', 0, 0, 0), -- LEAF
  (56, 'Akron Sound', 0, 0, 0), -- LEAF
  (57, 'Al jeel', 0, 0, 0), -- LEAF
  (58, 'Al-Jadīd', 0, 0, 0), -- LEAF
  (59, 'Albanian Folk Music', 0, 3, 0), -- 3 children
  (60, 'Aleke', 0, 0, 0), -- LEAF
  (61, 'Alevi Folk Music', 0, 0, 0), -- LEAF
  (62, 'Algerian Chaabi', 0, 0, 0), -- LEAF
  (63, 'Algorave', 0, 0, 0), -- LEAF
  (64, 'Alloukou', 0, 0, 0), -- LEAF
  (65, 'Alpenrock', 0, 0, 0), -- LEAF
  (66, 'Alpine Folk Music', 0, 4, 0), -- 4 children
  (67, 'Alsatian Folk Music', 0, 0, 0), -- LEAF
  (68, 'Alt-Country', 5, 1, 7), -- 1 children
  (69, 'Alt-Pop', 5, 0, 5), -- LEAF
  (70, 'Altai Music', 0, 0, 0), -- LEAF
  (71, 'Alternative Dance', 10, 2, 17), -- 2 children
  (72, 'Alternative Idol', 0, 0, 0), -- LEAF
  (73, 'Alternative Metal', 17, 4, 23), -- 4 children
  (74, 'Alternative R&B', 32, 0, 32), -- LEAF
  (75, 'Alternative Rock', 21, 32, 169), -- 32 children
  (76, 'Alté', 0, 0, 0), -- LEAF
  (77, 'Amami shimauta', 0, 0, 0), -- LEAF
  (78, 'Amapiano', 0, 1, 0), -- 1 children
  (79, 'Amazigh Music', 0, 8, 0), -- 8 children
  (80, 'Ambasse bey', 0, 0, 0), -- LEAF
  (81, 'Ambient', 75, 6, 135), -- 6 children
  (82, 'Ambient Americana', 1, 0, 1), -- LEAF
  (83, 'Ambient Dub', 4, 0, 4), -- LEAF
  (84, 'Ambient House', 1, 0, 1), -- LEAF
  (85, 'Ambient Noise Wall', 1, 0, 1), -- LEAF
  (86, 'Ambient Plugg', 1, 0, 1), -- LEAF
  (87, 'Ambient Pop', 33, 0, 33), -- LEAF
  (88, 'Ambient Techno', 13, 0, 13), -- LEAF
  (89, 'Ambient Trance', 1, 0, 1), -- LEAF
  (90, 'Ambrosian Chant', 0, 0, 0), -- LEAF
  (91, 'American Folk Music', 0, 26, 4), -- 26 children
  (92, 'American Gamelan', 0, 0, 0), -- LEAF
  (93, 'American Primitivism', 1, 0, 1), -- LEAF
  (94, 'Americana', 7, 0, 7), -- LEAF
  (95, 'Amigacore', 0, 0, 0), -- LEAF
  (96, 'Anarcho-Punk', 5, 0, 5), -- LEAF
  (97, 'Anatolian Rock', 1, 0, 1), -- LEAF
  (98, 'Ancient Chinese Music', 0, 0, 0), -- LEAF
  (99, 'Ancient Egyptian Music', 0, 0, 0), -- LEAF
  (100, 'Ancient Greek Music', 0, 0, 0), -- LEAF
  (101, 'Ancient Levitical Music', 0, 0, 0), -- LEAF
  (102, 'Ancient Music', 0, 7, 0), -- 7 children
  (103, 'Ancient Roman Music', 0, 0, 0), -- LEAF
  (104, 'Andalusian Classical Music', 0, 0, 0), -- LEAF
  (105, 'Andalusian Folk Music', 0, 2, 0), -- 2 children
  (106, 'Andean New Age', 0, 0, 0), -- LEAF
  (107, 'Anglican Chant', 0, 0, 0), -- LEAF
  (108, 'Animal Sounds', 1, 3, 3), -- 3 children
  (109, 'Anti-Folk', 5, 0, 5), -- LEAF
  (110, 'AOR', 1, 0, 1), -- LEAF
  (111, 'Apala', 0, 0, 0), -- LEAF
  (112, 'Appalachian Folk Music', 4, 1, 4), -- 1 children
  (113, 'Aquacrunk', 1, 0, 1), -- LEAF
  (114, 'Arabesk', 0, 0, 0), -- LEAF
  (115, 'Arabesque Rap', 0, 0, 0), -- LEAF
  (116, 'Arabic Bellydance Music', 0, 1, 0), -- 1 children
  (117, 'Arabic Classical Music', 2, 3, 2), -- 3 children
  (118, 'Arabic Folk Music', 1, 8, 1), -- 8 children
  (119, 'Arabic Jazz', 0, 0, 0), -- LEAF
  (120, 'Arabic Music', 1, 35, 4), -- 35 children
  (121, 'Arabic Pop', 0, 2, 0), -- 2 children
  (122, 'Aragonese Folk Music', 0, 0, 0), -- LEAF
  (123, 'Argentine Music', 0, 8, 0), -- 8 children
  (124, 'Armenian Church Music', 0, 0, 0), -- LEAF
  (125, 'Armenian Folk Music', 0, 1, 0), -- 1 children
  (126, 'Armenian Music', 0, 4, 0), -- 4 children
  (127, 'Aromanian Folk Music', 0, 0, 0), -- LEAF
  (128, 'Arrocha', 0, 2, 0), -- 2 children
  (129, 'Arrocha funk', 0, 0, 0), -- LEAF
  (130, 'Arrocha sertanejo', 0, 0, 0), -- LEAF
  (131, 'Arrochadeira', 0, 0, 0), -- LEAF
  (132, 'Ars antiqua', 0, 0, 0), -- LEAF
  (133, 'Ars nova', 0, 0, 0), -- LEAF
  (134, 'Ars subtilior', 0, 0, 0), -- LEAF
  (135, 'Art Pop', 69, 0, 69), -- LEAF
  (136, 'Art Punk', 31, 1, 31), -- 1 children
  (137, 'Art Rock', 45, 0, 45), -- LEAF
  (138, 'Art Song', 0, 5, 1), -- 5 children
  (139, 'Artcore', 0, 0, 0), -- LEAF
  (140, 'Ashkenazi Cantorial Music', 0, 0, 0), -- LEAF
  (141, 'Ashkenazi Music', 0, 3, 1), -- 3 children
  (142, 'Asian Music', 0, 380, 11), -- 380 children
  (143, 'Asian Rock', 0, 0, 0), -- LEAF
  (144, 'Asian Underground', 0, 0, 0), -- LEAF
  (145, 'ASMR', 1, 0, 1), -- LEAF
  (146, 'Assamese Folk Music', 0, 0, 0), -- LEAF
  (147, 'Assiko', 0, 0, 0), -- LEAF
  (148, 'Assyrian Folk Music', 0, 0, 0), -- LEAF
  (149, 'Asturian Folk Music', 0, 0, 0), -- LEAF
  (150, 'Athabaskan Fiddling', 0, 0, 0), -- LEAF
  (151, 'Atlanta Bass', 0, 0, 0), -- LEAF
  (152, 'Atmospheric Black Metal', 27, 1, 32), -- 1 children
  (153, 'Atmospheric Drum and Bass', 7, 0, 7), -- LEAF
  (154, 'Atmospheric Sludge Metal', 11, 0, 11), -- LEAF
  (155, 'Audio Documentary', 1, 0, 1), -- LEAF
  (156, 'Aussie Pub Rock', 0, 0, 0), -- LEAF
  (157, 'Australian Folk Music', 0, 0, 0), -- LEAF
  (158, 'Austronesian Music', 0, 51, 0), -- 51 children
  (159, 'Authenticité', 0, 0, 0), -- LEAF
  (160, 'Autonomic', 0, 0, 0), -- LEAF
  (161, 'Auvergnat Folk Music', 0, 0, 0), -- LEAF
  (162, 'Avant-Folk', 26, 1, 27), -- 1 children
  (163, 'Avant-Garde Jazz', 29, 5, 38), -- 5 children
  (164, 'Avant-Garde Metal', 56, 0, 56), -- LEAF
  (165, 'Avant-Prog', 22, 2, 40), -- 2 children
  (166, 'Avanzada', 0, 0, 0), -- LEAF
  (167, 'Avar Folk Music', 0, 0, 0), -- LEAF
  (168, 'Avtorskaya pesnya', 0, 1, 0), -- 1 children
  (169, 'Axé', 0, 3, 0), -- 3 children
  (170, 'Ayyalah', 0, 0, 0), -- LEAF
  (171, 'Azerbaijani Mugham', 0, 0, 0), -- LEAF
  (172, 'Azerbaijani Music', 0, 4, 0), -- 4 children
  (173, 'Azmari', 0, 0, 0), -- LEAF
  (174, 'Bacardi', 0, 0, 0), -- LEAF
  (175, 'Bachata', 0, 0, 0), -- LEAF
  (176, 'Bachatón', 0, 0, 0), -- LEAF
  (177, 'Bagad', 0, 0, 0), -- LEAF
  (178, 'Baganda Music', 0, 3, 0), -- 3 children
  (179, 'Bagatelle', 0, 0, 0), -- LEAF
  (180, 'Baggy', 4, 0, 4), -- LEAF
  (181, 'Baguala', 0, 0, 0), -- LEAF
  (182, 'Baila', 0, 0, 0), -- LEAF
  (183, 'Bailecito', 0, 0, 0), -- LEAF
  (184, 'Baisha xiyue', 0, 0, 0), -- LEAF
  (185, 'Baithak gana', 0, 0, 0), -- LEAF
  (186, 'Baião', 0, 0, 0), -- LEAF
  (187, 'Bakersfield Sound', 0, 0, 0), -- LEAF
  (188, 'Balani Show', 0, 0, 0), -- LEAF
  (189, 'Balearic Beat', 0, 0, 0), -- LEAF
  (190, 'Balinese Gamelan', 0, 6, 0), -- 6 children
  (191, 'Balinese Music', 0, 8, 0), -- 8 children
  (192, 'Balitaw', 0, 0, 0), -- LEAF
  (193, 'Balkan Brass Band', 0, 0, 0), -- LEAF
  (194, 'Balkan Folk Music', 1, 29, 1), -- 29 children
  (195, 'Balkan Music', 0, 44, 1), -- 44 children
  (196, 'Balkan Pop-Folk', 0, 8, 0), -- 8 children
  (197, 'Ballad Opera', 0, 0, 0), -- LEAF
  (198, 'Ballet', 1, 3, 1), -- 3 children
  (199, 'Ballet de cour', 0, 0, 0), -- LEAF
  (200, 'Ballroom', 1, 0, 1), -- LEAF
  (201, 'Balochi Music', 0, 0, 0), -- LEAF
  (202, 'Baltic Folk Music', 0, 2, 0), -- 2 children
  (203, 'Baltimore Club', 1, 0, 1), -- LEAF
  (204, 'Balto-Finnic Folk Music', 0, 6, 0), -- 6 children
  (205, 'Bamar Folk Music', 0, 0, 0), -- LEAF
  (206, 'Bamar Music', 0, 3, 0), -- 3 children
  (207, 'Bambuco', 0, 0, 0), -- LEAF
  (208, 'Banda de pífano', 0, 0, 0), -- LEAF
  (209, 'Banda Music', 0, 0, 0), -- LEAF
  (210, 'Banda sinaloense', 0, 2, 0), -- 2 children
  (211, 'Bandari', 0, 0, 0), -- LEAF
  (212, 'Bandas de viento de México', 0, 3, 0), -- 3 children
  (213, 'Bandinha', 0, 0, 0), -- LEAF
  (214, 'Banga', 0, 0, 0), -- LEAF
  (215, 'Bantengan', 0, 0, 0), -- LEAF
  (216, 'Baqashot', 0, 0, 0), -- LEAF
  (217, 'Barber Beats', 0, 0, 0), -- LEAF
  (218, 'Barbershop', 0, 1, 0), -- 1 children
  (219, 'Bard Rock', 0, 0, 0), -- LEAF
  (220, 'Bardcore', 0, 0, 0), -- LEAF
  (221, 'Baroque Music', 2, 4, 2), -- 4 children
  (222, 'Baroque Pop', 9, 0, 9), -- LEAF
  (223, 'Baroque Suite', 0, 0, 0), -- LEAF
  (224, 'Bashkir Folk Music', 0, 0, 0), -- LEAF
  (225, 'Bashment Soca', 0, 0, 0), -- LEAF
  (226, 'Basque Folk Music', 0, 1, 0), -- 1 children
  (227, 'Bass House', 1, 1, 1), -- 1 children
  (228, 'Bassline', 1, 0, 1), -- LEAF
  (229, 'Batak Music', 0, 2, 0), -- 2 children
  (230, 'Batida', 0, 0, 0), -- LEAF
  (231, 'Batidão romântico', 0, 0, 0), -- LEAF
  (232, 'Batonebi Songs', 0, 0, 0), -- LEAF
  (233, 'Battle Rap', 0, 0, 0), -- LEAF
  (234, 'Battle Record', 0, 0, 0), -- LEAF
  (235, 'Batucada', 1, 0, 1), -- LEAF
  (236, 'Batuque', 0, 0, 0), -- LEAF
  (237, 'Baul gaan', 0, 0, 0), -- LEAF
  (238, 'Bay Area Hip Hop', 0, 0, 0), -- LEAF
  (239, 'Bay Area Thrash Metal', 0, 0, 0), -- LEAF
  (240, 'Bayawan', 0, 0, 0), -- LEAF
  (241, 'Beach Music', 0, 0, 0), -- LEAF
  (242, 'Beat', 0, 4, 0), -- 4 children
  (243, 'Beat bolha', 0, 0, 0), -- LEAF
  (244, 'Beat bruxaria', 0, 0, 0), -- LEAF
  (245, 'Beat fino', 0, 0, 0), -- LEAF
  (246, 'Beat Poetry', 0, 0, 0), -- LEAF
  (247, 'Beat Rock', 0, 0, 0), -- LEAF
  (248, 'Beatboxing', 1, 0, 1), -- LEAF
  (249, 'Beatdown Hardcore', 4, 0, 4), -- LEAF
  (250, 'Bebop', 0, 0, 0), -- LEAF
  (251, 'Bedouin Music', 0, 4, 0), -- 4 children
  (252, 'Bedroom Pop', 2, 0, 2), -- LEAF
  (253, 'Beijing New Sound', 0, 0, 0), -- LEAF
  (254, 'Beja Music', 0, 0, 0), -- LEAF
  (255, 'Belarusian Folk Music', 0, 0, 0), -- LEAF
  (256, 'Bele', 0, 0, 0), -- LEAF
  (257, 'Belgian Techno', 1, 0, 1), -- LEAF
  (258, 'Belwo', 0, 0, 0), -- LEAF
  (259, 'Bend-skin', 0, 0, 0), -- LEAF
  (260, 'Benga', 0, 0, 0), -- LEAF
  (261, 'Bengali Folk Music', 0, 1, 0), -- 1 children
  (262, 'Beni', 0, 0, 0), -- LEAF
  (263, 'Benna', 0, 0, 0), -- LEAF
  (264, 'Bentonia School', 0, 0, 0), -- LEAF
  (265, 'Beompae', 0, 0, 0), -- LEAF
  (266, 'Berlin School', 3, 0, 3), -- LEAF
  (267, 'Bernese Dialect Scene', 0, 0, 0), -- LEAF
  (268, 'Bhajan', 0, 0, 0), -- LEAF
  (269, 'Bhangra', 0, 1, 0), -- 1 children
  (270, 'Bhojpuri Folk Music', 0, 1, 0), -- 1 children
  (271, 'Big Band', 1, 2, 5), -- 2 children
  (272, 'Big Beat', 4, 0, 4), -- LEAF
  (273, 'Big Music', 0, 0, 0), -- LEAF
  (274, 'Big Room House', 0, 0, 0), -- LEAF
  (275, 'Big Room Trance', 0, 0, 0), -- LEAF
  (276, 'Biguine', 0, 0, 0), -- LEAF
  (277, 'Bikutsi', 0, 0, 0), -- LEAF
  (278, 'Binaural Beats', 0, 0, 0), -- LEAF
  (279, 'Biraha', 0, 0, 0), -- LEAF
  (280, 'Bird Sounds', 0, 0, 0), -- LEAF
  (281, 'Birmingham Sound', 1, 0, 1), -- LEAF
  (282, 'Bit Music', 0, 10, 7), -- 10 children
  (283, 'Bitpop', 2, 0, 2), -- LEAF
  (285, 'Black ''n'' Roll', 0, 0, 0), -- LEAF
  (286, 'Black Ambient', 4, 0, 4), -- LEAF
  (287, 'Black Gospel', 0, 4, 0), -- 4 children
  (288, 'Black Metal', 37, 13, 69), -- 13 children
  (289, 'Black MIDI', 0, 0, 0), -- LEAF
  (290, 'Black Noise', 9, 0, 9), -- LEAF
  (291, 'Black Rio', 0, 0, 0), -- LEAF
  (292, 'Blackened Crust', 6, 0, 6), -- LEAF
  (293, 'Blackened Death Metal', 3, 0, 3), -- LEAF
  (294, 'Blackgaze', 7, 0, 7), -- LEAF
  (295, 'Bleep Techno', 0, 0, 0), -- LEAF
  (296, 'Bloghouse', 1, 0, 1), -- LEAF
  (297, 'Blue-Eyed Soul', 1, 0, 1), -- LEAF
  (298, 'Bluegrass', 3, 4, 3), -- 4 children
  (299, 'Bluegrass Gospel', 0, 0, 0), -- LEAF
  (300, 'Blues', 1, 20, 5), -- 20 children
  (301, 'Blues Rock', 4, 1, 5), -- 1 children
  (302, 'Bocet', 0, 0, 0), -- LEAF
  (303, 'Boduberu', 0, 0, 0), -- LEAF
  (304, 'Bogino duu', 0, 0, 0), -- LEAF
  (305, 'Bhojpuri Pop', 0, 0, 0), -- LEAF
  (306, 'Bolero', 0, 2, 0), -- 2 children
  (307, 'Bolero español', 0, 0, 0), -- LEAF
  (308, 'Bolero son', 0, 0, 0), -- LEAF
  (309, 'Bolero Việt Nam', 0, 0, 0), -- LEAF
  (310, 'Bolero-Beat', 0, 0, 0), -- LEAF
  (311, 'Bolivian Huayño', 0, 0, 0), -- LEAF
  (312, 'Bomba', 0, 0, 0), -- LEAF
  (313, 'Bongo Flava', 0, 0, 0), -- LEAF
  (314, 'Boogaloo', 0, 0, 0), -- LEAF
  (315, 'Boogie', 5, 0, 5), -- LEAF
  (316, 'Boogie Rock', 1, 0, 1), -- LEAF
  (317, 'Boogie Woogie', 0, 0, 0), -- LEAF
  (318, 'Boom Bap', 55, 0, 55), -- LEAF
  (319, 'Bop', 2, 0, 2), -- LEAF
  (320, 'Bosnian Folk Music', 0, 2, 0), -- 2 children
  (321, 'Bossa nova', 2, 0, 2), -- LEAF
  (322, 'Bosstown Sound', 0, 0, 0), -- LEAF
  (323, 'Boston Hardcore', 0, 0, 0), -- LEAF
  (324, 'Bounce', 0, 1, 0), -- 1 children
  (325, 'Bounce Beat', 0, 0, 0), -- LEAF
  (326, 'Bouncy Techno', 0, 0, 0), -- LEAF
  (327, 'Bouyon', 0, 0, 0), -- LEAF
  (328, 'Boy Band', 0, 0, 0), -- LEAF
  (329, 'Boyfriend Country', 0, 0, 0), -- LEAF
  (330, 'Brazilian Bass', 0, 2, 0), -- 2 children
  (331, 'Brazilian Classical Music', 0, 1, 0), -- 1 children
  (332, 'Brazilian Folk Music', 1, 21, 2), -- 21 children
  (333, 'Brazilian Music', 0, 119, 10), -- 119 children
  (334, 'Brazilian Phonk', 0, 0, 0), -- LEAF
  (335, 'Break-In', 0, 0, 0), -- LEAF
  (336, 'Breakbeat', 5, 16, 17), -- 16 children
  (337, 'Breakbeat Hardcore', 2, 4, 4), -- 4 children
  (338, 'Breakbeat Kota', 0, 1, 0), -- 1 children
  (339, 'Breakcore', 13, 3, 13), -- 3 children
  (340, 'Breakstep', 0, 0, 0), -- LEAF
  (341, 'Brega', 0, 8, 0), -- 8 children
  (342, 'Brega calypso', 0, 0, 0), -- LEAF
  (343, 'Brega funk', 0, 1, 0), -- 1 children
  (344, 'Bregadeira', 0, 0, 0), -- LEAF
  (345, 'Breton Celtic Folk Music', 0, 1, 0), -- 1 children
  (346, 'Breton Folk Music', 0, 3, 0), -- 3 children
  (347, 'Briddim', 1, 0, 1), -- LEAF
  (348, 'Brill Building', 2, 0, 2), -- LEAF
  (349, 'Bristol Sound', 0, 0, 0), -- LEAF
  (350, 'Britcore', 0, 0, 0), -- LEAF
  (351, 'Britfunk', 0, 0, 0), -- LEAF
  (352, 'British Beat Boom', 0, 1, 0), -- 1 children
  (353, 'British Blues', 0, 0, 0), -- LEAF
  (354, 'British Brass Band', 1, 0, 1), -- LEAF
  (355, 'British Dance Band', 0, 0, 0), -- LEAF
  (356, 'British Folk Rock', 0, 0, 0), -- LEAF
  (357, 'British Music', 0, 25, 2), -- 25 children
  (358, 'British Rhythm & Blues', 0, 0, 0), -- LEAF
  (359, 'British Trad Jazz', 0, 0, 0), -- LEAF
  (360, 'Britpop', 0, 0, 0), -- LEAF
  (361, 'Brno Alternative Scene', 0, 0, 0), -- LEAF
  (362, 'Bro-Country', 0, 0, 0), -- LEAF
  (363, 'Broadband Noise', 0, 0, 0), -- LEAF
  (364, 'BRock', 0, 0, 0), -- LEAF
  (365, 'Broken Beat', 0, 0, 0), -- LEAF
  (366, 'Broken Transmission', 1, 0, 1), -- LEAF
  (367, 'Bronx Drill', 0, 0, 0), -- LEAF
  (368, 'Brony Music', 0, 0, 0), -- LEAF
  (369, 'Brooklyn Drill', 0, 0, 0), -- LEAF
  (370, 'Brostep', 2, 6, 5), -- 6 children
  (371, 'Brukdown', 0, 0, 0), -- LEAF
  (372, 'Brutal Death Metal', 10, 1, 14), -- 1 children
  (373, 'Brutal Prog', 22, 0, 22), -- LEAF
  (374, 'Bubblegum', 0, 0, 0), -- LEAF
  (375, 'Bubblegum Bass', 3, 0, 3), -- LEAF
  (376, 'Bubblegum Dance', 0, 0, 0), -- LEAF
  (377, 'Bubbling', 0, 0, 0), -- LEAF
  (378, 'Bubbling House', 0, 0, 0), -- LEAF
  (379, 'Buchiage Trance', 0, 0, 0), -- LEAF
  (380, 'Buddhist Music', 0, 4, 0), -- 4 children
  (381, 'Budots', 0, 0, 0), -- LEAF
  (382, 'Buganda Royal Court Music', 0, 0, 0), -- LEAF
  (383, 'Bugle Call', 0, 0, 0), -- LEAF
  (384, 'Bulawayo Jazz', 0, 0, 0), -- LEAF
  (385, 'Bulería', 0, 0, 0), -- LEAF
  (386, 'Bulgarian Folk Music', 0, 0, 0), -- LEAF
  (387, 'Bullerengue', 0, 0, 0), -- LEAF
  (388, 'Burger-Highlife', 0, 0, 0), -- LEAF
  (389, 'Burmese Classical Music', 0, 0, 0), -- LEAF
  (390, 'Burning Spirits', 1, 0, 1), -- LEAF
  (391, 'Burrakatha', 0, 0, 0), -- LEAF
  (392, 'Burushaski Folk Music', 0, 0, 0), -- LEAF
  (393, 'Buryat Folk Music', 0, 0, 0), -- LEAF
  (394, 'Byzantine Chant', 0, 0, 0), -- LEAF
  (395, 'Byzantine Music', 1, 1, 1), -- 1 children
  (396, 'Bérite Club', 1, 0, 1), -- LEAF
  (397, 'C-Pop', 0, 5, 0), -- 5 children
  (398, 'C86', 0, 0, 0), -- LEAF
  (399, 'Ca trù', 0, 0, 0), -- LEAF
  (400, 'Cabaret', 2, 0, 2), -- LEAF
  (401, 'Cabo-Zouk', 0, 0, 0), -- LEAF
  (402, 'Cadence Lypso', 0, 0, 0), -- LEAF
  (403, 'Cadence rampa', 0, 0, 0), -- LEAF
  (404, 'Cajun Music', 0, 1, 0), -- 1 children
  (405, 'Cakewalk', 0, 0, 0), -- LEAF
  (406, 'Calipso venezolano', 0, 0, 0), -- LEAF
  (407, 'Calypso', 1, 2, 1), -- 2 children
  (408, 'Cambodian Pop', 0, 1, 0), -- 1 children
  (409, 'Campursari', 0, 0, 0), -- LEAF
  (410, 'Campus Folk', 0, 0, 0), -- LEAF
  (411, 'Canadian Folk Music', 0, 6, 0), -- 6 children
  (412, 'Canadian Maritime Folk', 0, 2, 0), -- 2 children
  (413, 'Canarian Folk Music', 0, 0, 0), -- LEAF
  (414, 'Canción melódica', 0, 2, 0), -- 2 children
  (415, 'Candombe', 0, 0, 0), -- LEAF
  (416, 'Candombe beat', 0, 0, 0), -- LEAF
  (417, 'Candomblé Music', 0, 0, 0), -- LEAF
  (418, 'Cantata', 0, 0, 0), -- LEAF
  (419, 'Cante alentejano', 0, 0, 0), -- LEAF
  (420, 'Canterbury Scene', 1, 1, 1), -- 1 children
  (421, 'Canto a lo poeta', 0, 0, 0), -- LEAF
  (422, 'Canto beneventano', 0, 0, 0), -- LEAF
  (423, 'Canto cardenche', 0, 0, 0), -- LEAF
  (424, 'Canto degli Alpini', 0, 0, 0), -- LEAF
  (425, 'Canto mozárabe', 0, 0, 0), -- LEAF
  (426, 'Cantonese Opera', 0, 0, 0), -- LEAF
  (427, 'Cantopop', 0, 0, 0), -- LEAF
  (428, 'Cantoria', 0, 1, 0), -- 1 children
  (429, 'Cantu a chiterra', 0, 0, 0), -- LEAF
  (430, 'Cantu a tenore', 0, 0, 0), -- LEAF
  (431, 'Canzona', 0, 0, 0), -- LEAF
  (432, 'Canzone d''autore', 0, 0, 0), -- LEAF
  (433, 'Canzone napoletana', 0, 0, 0), -- LEAF
  (434, 'Canzone neomelodica', 0, 0, 0), -- LEAF
  (435, 'Cape Breton Fiddling', 0, 0, 0), -- LEAF
  (436, 'Cape Breton Folk Music', 0, 1, 0), -- 1 children
  (437, 'Cape Jazz', 0, 0, 0), -- LEAF
  (438, 'Cape Verdean Music', 0, 4, 0), -- 4 children
  (439, 'Capoeira Music', 0, 0, 0), -- LEAF
  (440, 'Caporal', 0, 0, 0), -- LEAF
  (441, 'Capriccio', 0, 0, 0), -- LEAF
  (442, 'Car Audio Bass', 0, 0, 0), -- LEAF
  (443, 'Caribbean Folk Music', 1, 16, 1), -- 16 children
  (444, 'Caribbean Music', 0, 126, 14), -- 126 children
  (445, 'Carimbó', 0, 0, 0), -- LEAF
  (446, 'Carnatic Classical Music', 0, 1, 0), -- 1 children
  (447, 'Carnaval cruceño', 0, 0, 0), -- LEAF
  (448, 'Carnavalito', 0, 0, 0), -- LEAF
  (449, 'Carols', 0, 0, 0), -- LEAF
  (450, 'Carranga', 0, 0, 0), -- LEAF
  (451, 'Cartoon Music', 1, 0, 1), -- LEAF
  (452, 'Cascadian Black Metal', 0, 0, 0), -- LEAF
  (453, 'Catalan Folk Music', 0, 1, 0), -- 1 children
  (454, 'Caucasian Folk Music', 0, 8, 0), -- 8 children
  (455, 'Caucasian Music', 0, 11, 0), -- 11 children
  (456, 'CCM', 0, 4, 0), -- 4 children
  (457, 'Celtic Chant', 0, 0, 0), -- LEAF
  (458, 'Celtic Electronica', 1, 0, 1), -- LEAF
  (459, 'Celtic Folk Music', 0, 18, 0), -- 18 children
  (460, 'Celtic Metal', 0, 0, 0), -- LEAF
  (461, 'Celtic New Age', 0, 0, 0), -- LEAF
  (462, 'Celtic Punk', 0, 0, 0), -- LEAF
  (463, 'Celtic Rock', 0, 0, 0), -- LEAF
  (464, 'Central African Music', 0, 23, 0), -- 23 children
  (465, 'Central American Music', 0, 11, 0), -- 11 children
  (466, 'Central Asian Music', 0, 35, 1), -- 35 children
  (467, 'Central Asian Throat Singing', 0, 3, 1), -- 3 children
  (468, 'Chacarera', 0, 0, 0), -- LEAF
  (469, 'Chachachá', 0, 0, 0), -- LEAF
  (470, 'Chalga', 0, 0, 0), -- LEAF
  (471, 'Chamamé', 0, 1, 0), -- 1 children
  (472, 'Chamamé tropical', 0, 0, 0), -- LEAF
  (473, 'Chamarrita açoriana', 0, 0, 0), -- LEAF
  (474, 'Chamarrita rioplatense', 0, 0, 0), -- LEAF
  (475, 'Chamber Folk', 16, 0, 16), -- LEAF
  (476, 'Chamber Jazz', 6, 0, 6), -- LEAF
  (477, 'Chamber Music', 18, 1, 18), -- 1 children
  (478, 'Chamber Pop', 21, 0, 21), -- LEAF
  (479, 'Champeta', 0, 0, 0), -- LEAF
  (480, 'Changa tuki', 1, 0, 1), -- LEAF
  (481, 'Change Ringing', 0, 0, 0), -- LEAF
  (482, 'Changjak gugak', 0, 0, 0), -- LEAF
  (483, 'Changüí', 0, 0, 0), -- LEAF
  (484, 'Chanson', 0, 5, 0), -- 5 children
  (485, 'Chanson alternative', 0, 0, 0), -- LEAF
  (486, 'Chanson québécoise', 0, 0, 0), -- LEAF
  (487, 'Chanson réaliste', 0, 0, 0), -- LEAF
  (488, 'Chanson à texte', 0, 0, 0), -- LEAF
  (489, 'Chaozhou xianshi', 0, 0, 0), -- LEAF
  (490, 'Chap Hop', 0, 0, 0), -- LEAF
  (491, 'Character Piece', 0, 2, 0), -- 2 children
  (492, 'Chazzanut', 0, 1, 0), -- 1 children
  (493, 'Chechen Folk Music', 0, 0, 0), -- LEAF
  (494, 'Chicago Blues', 0, 0, 0), -- LEAF
  (495, 'Chicago Drill', 7, 1, 7), -- 1 children
  (496, 'Chicago Hard House', 0, 1, 0), -- 1 children
  (497, 'Chicago House', 0, 0, 0), -- LEAF
  (498, 'Chicago No Wave', 0, 0, 0), -- LEAF
  (499, 'Chicago Polka', 0, 0, 0), -- LEAF
  (500, 'Chicago School', 0, 0, 0), -- LEAF
  (501, 'Chicago Soul', 1, 0, 1), -- LEAF
  (502, 'Chicano Rap', 0, 0, 0), -- LEAF
  (503, 'Chicha', 0, 0, 0), -- LEAF
  (504, 'Chikipunk', 0, 0, 0), -- LEAF
  (505, 'Children''s Music', 1, 3, 2), -- 3 children
  (506, 'Chilean Music', 0, 12, 0), -- 12 children
  (507, 'Chilena', 0, 0, 0), -- LEAF
  (508, 'Chillout', 0, 8, 34), -- 8 children
  (509, 'Chillstep', 1, 0, 1), -- LEAF
  (510, 'Chillsynth', 1, 0, 1), -- LEAF
  (511, 'Chillwave', 4, 1, 4), -- 1 children
  (512, 'Chilote Music', 0, 0, 0), -- LEAF
  (513, 'Chimaychi', 0, 0, 0), -- LEAF
  (514, 'Chimurenga', 0, 0, 0), -- LEAF
  (515, 'Chinese Classical Music', 0, 5, 0), -- 5 children
  (516, 'Chinese Folk Music', 1, 6, 1), -- 6 children
  (517, 'Chinese Literati Music', 0, 0, 0), -- LEAF
  (518, 'Chinese Music', 0, 36, 1), -- 36 children
  (519, 'Chinese Opera', 0, 9, 0), -- 9 children
  (520, 'Chipmunk Soul', 15, 0, 15), -- LEAF
  (521, 'Chiptune', 1, 0, 1), -- LEAF
  (522, 'Chopped and Screwed', 3, 0, 3), -- LEAF
  (523, 'Chopper', 0, 0, 0), -- LEAF
  (524, 'Choral', 3, 2, 3), -- 2 children
  (525, 'Choral Concerto', 0, 0, 0), -- LEAF
  (526, 'Choral Symphony', 0, 0, 0), -- LEAF
  (527, 'Choro', 0, 1, 1), -- 1 children
  (528, 'Chotis madrileño', 0, 0, 0), -- LEAF
  (529, 'Christian Hardcore', 0, 0, 0), -- LEAF
  (530, 'Christian Hip Hop', 0, 0, 0), -- LEAF
  (531, 'Christian Liturgical Music', 1, 24, 2), -- 24 children
  (532, 'Christian Rock', 0, 1, 0), -- 1 children
  (533, 'Christmas Music', 0, 1, 0), -- 1 children
  (534, 'Chukchi Folk Music', 0, 0, 0), -- LEAF
  (535, 'Chuntunqui romántico', 0, 0, 0), -- LEAF
  (536, 'Chutney', 0, 1, 0), -- 1 children
  (537, 'Chutney Soca', 0, 0, 0), -- LEAF
  (538, 'Chuvash Folk Music', 0, 0, 0), -- LEAF
  (539, 'Chèo', 0, 0, 0), -- LEAF
  (540, 'Chöd', 0, 0, 0), -- LEAF
  (541, 'Cilokaq', 0, 0, 0), -- LEAF
  (542, 'Cinematic Classical', 2, 2, 3), -- 2 children
  (543, 'Ciranda', 0, 0, 0), -- LEAF
  (544, 'Circassian Folk Music', 0, 0, 0), -- LEAF
  (545, 'Circus March', 1, 0, 1), -- LEAF
  (546, 'City Pop', 3, 1, 3), -- 1 children
  (547, 'Classic Ragtime', 0, 0, 0), -- LEAF
  (548, 'Classical Crossover', 1, 1, 1), -- 1 children
  (549, 'Classical March', 1, 0, 1), -- LEAF
  (550, 'Classical Music', 0, 213, 59), -- 213 children
  (551, 'Classical Period', 0, 0, 0), -- LEAF
  (552, 'Cleveland Punk', 0, 0, 0), -- LEAF
  (553, 'Close Harmony', 0, 0, 0), -- LEAF
  (554, 'Cloud Rap', 51, 0, 51), -- LEAF
  (555, 'Clube da esquina', 0, 0, 0), -- LEAF
  (556, 'Cocktail Nation', 2, 0, 2), -- LEAF
  (557, 'Coco', 0, 2, 0), -- 2 children
  (558, 'Coke Rap', 8, 0, 8), -- LEAF
  (559, 'Coladeira', 0, 0, 0), -- LEAF
  (560, 'Coldwave', 4, 0, 4), -- LEAF
  (561, 'Colinde', 0, 0, 0), -- LEAF
  (562, 'Colour Bass', 0, 0, 0), -- LEAF
  (563, 'Comedy', 0, 11, 4), -- 11 children
  (564, 'Comedy Rap', 0, 1, 0), -- 1 children
  (565, 'Comedy Rock', 3, 0, 3), -- LEAF
  (566, 'Comfy Synth', 3, 0, 3), -- LEAF
  (567, 'Comorian Music', 0, 0, 0), -- LEAF
  (568, 'Compas', 0, 0, 0), -- LEAF
  (569, 'Complextro', 0, 0, 0), -- LEAF
  (570, 'Comédie-ballet', 0, 0, 0), -- LEAF
  (571, 'Concert Band', 0, 0, 0), -- LEAF
  (572, 'Concert Spiritual', 0, 2, 0), -- 2 children
  (573, 'Concertina Band', 0, 0, 0), -- LEAF
  (574, 'Concerto', 0, 3, 0), -- 3 children
  (575, 'Concerto for Orchestra', 0, 0, 0), -- LEAF
  (576, 'Concerto grosso', 0, 0, 0), -- LEAF
  (577, 'Conducted Improvisation', 1, 0, 1), -- LEAF
  (578, 'Conga', 0, 0, 0), -- LEAF
  (579, 'Congolese Rumba', 0, 0, 0), -- LEAF
  (580, 'Conjunto andino', 0, 0, 0), -- LEAF
  (581, 'Conscious Hip Hop', 97, 0, 97), -- LEAF
  (582, 'Contemporary A Cappella', 0, 0, 0), -- LEAF
  (583, 'Contemporary Country', 0, 3, 0), -- 3 children
  (584, 'Contemporary Folk', 12, 22, 89), -- 22 children
  (585, 'Contemporary R&B', 22, 5, 50), -- 5 children
  (586, 'Contenance angloise', 0, 0, 0), -- LEAF
  (587, 'Cool Jazz', 2, 0, 2), -- LEAF
  (588, 'Coon Song', 0, 0, 0), -- LEAF
  (589, 'Copla', 0, 0, 0), -- LEAF
  (590, 'Coplas cajamarquinas', 0, 0, 0), -- LEAF
  (591, 'Coptic Music', 0, 0, 0), -- LEAF
  (592, 'Cornish Folk Music', 0, 0, 0), -- LEAF
  (593, 'Corrido', 0, 0, 0), -- LEAF
  (594, 'Corrido tumbado', 0, 0, 0), -- LEAF
  (595, 'Corsican Folk Music', 0, 1, 0), -- 1 children
  (596, 'Cosmic Country', 0, 0, 0), -- LEAF
  (597, 'Country', 0, 30, 14), -- 30 children
  (598, 'Country & Irish', 0, 0, 0), -- LEAF
  (599, 'Country Blues', 0, 5, 0), -- 5 children
  (600, 'Country Boogie', 0, 0, 0), -- LEAF
  (601, 'Country Folk', 1, 0, 1), -- LEAF
  (602, 'Country Gospel', 0, 1, 0), -- 1 children
  (603, 'Country Pop', 1, 4, 1), -- 4 children
  (604, 'Country Rap', 0, 0, 0), -- LEAF
  (605, 'Country Rock', 0, 1, 0), -- 1 children
  (606, 'Country Soul', 0, 0, 0), -- LEAF
  (607, 'Country Yodeling', 0, 0, 0), -- LEAF
  (608, 'Countrypolitan', 0, 0, 0), -- LEAF
  (609, 'Coupé-décalé', 0, 0, 0), -- LEAF
  (610, 'Cowboy Poetry', 0, 0, 0), -- LEAF
  (611, 'Cowpunk', 2, 0, 2), -- LEAF
  (612, 'Crack Rock Steady', 2, 0, 2), -- LEAF
  (613, 'Cretan Folk Music', 0, 1, 0), -- 1 children
  (614, 'Crime Jazz', 0, 0, 0), -- LEAF
  (615, 'Crimean Tatar Music', 0, 0, 0), -- LEAF
  (616, 'Crisálida sónica', 0, 0, 0), -- LEAF
  (617, 'Croatian Folk Music', 0, 1, 0), -- 1 children
  (618, 'Crossbreed', 0, 0, 0), -- LEAF
  (619, 'Crossover Thrash', 1, 0, 1), -- LEAF
  (620, 'Cruise', 0, 0, 0), -- LEAF
  (621, 'Crunk', 2, 0, 2), -- LEAF
  (622, 'Crunkcore', 0, 0, 0), -- LEAF
  (623, 'Crust Punk', 8, 3, 12), -- 3 children
  (624, 'Csango Folk Music', 0, 0, 0), -- LEAF
  (625, 'Csárdás', 0, 0, 0), -- LEAF
  (626, 'Cuarteto', 0, 0, 0), -- LEAF
  (627, 'Cuban Charanga', 0, 0, 0), -- LEAF
  (628, 'Cuban Music', 0, 28, 0), -- 28 children
  (629, 'Cubaton', 0, 1, 0), -- 1 children
  (630, 'Cuddlecore', 1, 0, 1), -- LEAF
  (631, 'Cueca', 0, 1, 0), -- 1 children
  (632, 'Cueca brava', 0, 0, 0), -- LEAF
  (633, 'Cumbia', 0, 19, 0), -- 19 children
  (634, 'Cumbia amazónica', 0, 0, 0), -- LEAF
  (635, 'Cumbia argentina', 0, 3, 0), -- 3 children
  (636, 'Cumbia chilena', 0, 1, 0), -- 1 children
  (637, 'Cumbia colombiana', 0, 0, 0), -- LEAF
  (638, 'Cumbia mexicana', 0, 2, 0), -- 2 children
  (639, 'Cumbia norteña mexicana', 0, 0, 0), -- LEAF
  (640, 'Cumbia norteña peruana', 0, 0, 0), -- LEAF
  (641, 'Cumbia peruana', 0, 4, 0), -- 4 children
  (642, 'Cumbia pop', 0, 0, 0), -- LEAF
  (643, 'Cumbia rebajada', 0, 0, 0), -- LEAF
  (644, 'Cumbia salvadoreña', 0, 0, 0), -- LEAF
  (645, 'Cumbia santafesina', 0, 0, 0), -- LEAF
  (646, 'Cumbia sonidera', 0, 1, 0), -- 1 children
  (647, 'Cumbia turra', 0, 0, 0), -- LEAF
  (648, 'Cumbia villera', 0, 0, 0), -- LEAF
  (649, 'Cumbiatón', 0, 0, 0), -- LEAF
  (650, 'Cuplé', 0, 0, 0), -- LEAF
  (651, 'Currulao', 0, 0, 0), -- LEAF
  (652, 'Cururu', 0, 0, 0), -- LEAF
  (653, 'Cyber Metal', 2, 0, 2), -- LEAF
  (654, 'Cybergrind', 5, 0, 5), -- LEAF
  (655, 'Czech Folk Music', 0, 0, 0), -- LEAF
  (656, 'Cải lương', 0, 0, 0), -- LEAF
  (657, 'D-Beat', 1, 0, 1), -- LEAF
  (658, 'D.C. Hardcore', 0, 1, 0), -- 1 children
  (659, 'Dabke', 0, 0, 0), -- LEAF
  (660, 'Dagestani Folk Music', 0, 1, 0), -- 1 children
  (661, 'Dagomba Music', 0, 0, 0), -- LEAF
  (662, 'Dance', 0, 341, 177), -- 341 children
  (663, 'Dance-Pop', 17, 8, 17), -- 8 children
  (664, 'Dance-Punk', 19, 1, 21), -- 1 children
  (665, 'Dance-Punk Revival', 7, 0, 7), -- LEAF
  (666, 'Dancefloor Drum and Bass', 0, 0, 0), -- LEAF
  (667, 'Dancehall', 1, 8, 1), -- 8 children
  (668, 'Dang-ak', 0, 0, 0), -- LEAF
  (669, 'Dangdut', 0, 1, 0), -- 1 children
  (670, 'Dangdut koplo', 0, 0, 0), -- LEAF
  (671, 'Danish Folk Music', 0, 0, 0), -- LEAF
  (672, 'Danmono', 0, 0, 0), -- LEAF
  (673, 'Dansbandsmusik', 0, 0, 0), -- LEAF
  (674, 'Dansktop', 0, 0, 0), -- LEAF
  (675, 'Danzón', 0, 0, 0), -- LEAF
  (676, 'Dariacore', 3, 0, 3), -- LEAF
  (677, 'Dark Ambient', 49, 2, 57), -- 2 children
  (678, 'Dark Cabaret', 5, 0, 5), -- LEAF
  (679, 'Dark Disco', 0, 0, 0), -- LEAF
  (680, 'Dark Electro', 0, 1, 1), -- 1 children
  (681, 'Dark Folk', 8, 0, 8), -- LEAF
  (682, 'Dark Garage', 0, 0, 0), -- LEAF
  (683, 'Dark Jazz', 0, 0, 0), -- LEAF
  (684, 'Dark Plugg', 1, 0, 1), -- LEAF
  (685, 'Dark Psytrance', 0, 2, 1), -- 2 children
  (686, 'Darkcore', 0, 0, 0), -- LEAF
  (687, 'Darkside', 2, 0, 2), -- LEAF
  (688, 'Darkstep', 2, 2, 2), -- 2 children
  (689, 'Darksynth', 2, 0, 2), -- LEAF
  (690, 'Darkwave', 10, 3, 31), -- 3 children
  (691, 'Darmstadt School', 0, 0, 0), -- LEAF
  (692, 'Data Sonification', 1, 0, 1), -- LEAF
  (693, 'Death ''n'' Roll', 1, 0, 1), -- LEAF
  (694, 'Death Doom Metal', 3, 0, 3), -- LEAF
  (695, 'Death Industrial', 20, 0, 20), -- LEAF
  (696, 'Death Metal', 18, 9, 58), -- 9 children
  (697, 'Deathchant Hardcore', 0, 0, 0), -- LEAF
  (698, 'Deathcore', 6, 1, 6), -- 1 children
  (699, 'Deathgrind', 16, 0, 16), -- LEAF
  (700, 'Deathrock', 4, 0, 4), -- LEAF
  (701, 'Deathstep', 2, 1, 2), -- 1 children
  (702, 'Dechovka', 0, 0, 0), -- LEAF
  (703, 'Deconstructed Club', 19, 0, 19), -- LEAF
  (704, 'Deejay', 0, 0, 0), -- LEAF
  (705, 'Deep Drum and Bass', 0, 0, 0), -- LEAF
  (706, 'Deep Funk', 3, 0, 3), -- LEAF
  (707, 'Deep House', 2, 1, 2), -- 1 children
  (708, 'Deep Soul', 2, 0, 2), -- LEAF
  (709, 'Deep Tech', 0, 0, 0), -- LEAF
  (710, 'Dek Bass', 0, 0, 0), -- LEAF
  (711, 'Delta Blues', 0, 1, 0), -- 1 children
  (712, 'Dembow', 0, 0, 0), -- LEAF
  (713, 'Demoscene', 0, 0, 0), -- LEAF
  (714, 'Demostyle', 0, 1, 0), -- 1 children
  (715, 'Dennery Segment', 0, 0, 0), -- LEAF
  (716, 'Denpa', 0, 0, 0), -- LEAF
  (717, 'Descarga', 0, 0, 0), -- LEAF
  (718, 'Descriptor', 0, 56, 17), -- 56 children
  (719, 'Desgarrada', 0, 0, 0), -- LEAF
  (720, 'Desi Hip Hop', 0, 0, 0), -- LEAF
  (721, 'Detroit Sound', 0, 2, 0), -- 2 children
  (722, 'Detroit Techno', 2, 0, 2), -- LEAF
  (723, 'Deutschpunk', 0, 0, 0), -- LEAF
  (724, 'Deutschrock', 0, 0, 0), -- LEAF
  (725, 'Dhaanto', 0, 0, 0), -- LEAF
  (726, 'Dhol tasha', 0, 0, 0), -- LEAF
  (727, 'Dhrupad', 2, 0, 2), -- LEAF
  (728, 'Digicore', 9, 0, 9), -- LEAF
  (729, 'Digital Cumbia', 0, 0, 0), -- LEAF
  (730, 'Digital Dancehall', 0, 0, 0), -- LEAF
  (731, 'Digital Fusion', 1, 0, 1), -- LEAF
  (732, 'Digital Hardcore', 12, 0, 12), -- LEAF
  (733, 'Dikir barat', 0, 0, 0), -- LEAF
  (734, 'Dimotika', 0, 0, 0), -- LEAF
  (735, 'Dinka Music', 0, 0, 0), -- LEAF
  (736, 'Dirty South', 2, 0, 2), -- LEAF
  (737, 'Disco', 9, 12, 22), -- 12 children
  (738, 'Disco polo', 0, 0, 0), -- LEAF
  (739, 'Disco Rap', 0, 0, 0), -- LEAF
  (740, 'Dissonant Black Metal', 10, 0, 10), -- LEAF
  (741, 'Dissonant Death Metal', 10, 0, 10), -- LEAF
  (742, 'Diva House', 2, 1, 2), -- 1 children
  (743, 'Divertissement', 0, 0, 0), -- LEAF
  (744, 'Dixieland', 0, 0, 0), -- LEAF
  (745, 'Djanba', 0, 0, 0), -- LEAF
  (746, 'Djent', 1, 1, 1), -- 1 children
  (747, 'DMV Hip Hop', 0, 0, 0), -- LEAF
  (748, 'Doble paso', 0, 0, 0), -- LEAF
  (749, 'Dobrado', 0, 0, 0), -- LEAF
  (750, 'Doină', 0, 0, 0), -- LEAF
  (751, 'Dolewave', 0, 0, 0), -- LEAF
  (752, 'Dominican Music', 0, 8, 0), -- 8 children
  (753, 'Dondang sayang', 0, 0, 0), -- LEAF
  (754, 'Dongjing', 0, 0, 0), -- LEAF
  (755, 'Donosti Sound', 0, 0, 0), -- LEAF
  (756, 'Doo-Wop', 3, 0, 3), -- LEAF
  (757, 'Doom Metal', 10, 4, 17), -- 4 children
  (758, 'Doom WAD Music', 0, 0, 0), -- LEAF
  (759, 'Doomcore', 0, 0, 0), -- LEAF
  (760, 'Doomgaze', 9, 0, 9), -- LEAF
  (761, 'Doskpop', 0, 0, 0), -- LEAF
  (762, 'Doujin Music', 0, 1, 0), -- 1 children
  (763, 'Downtempo', 19, 1, 28), -- 1 children
  (764, 'Downtempo Deathcore', 0, 0, 0), -- LEAF
  (765, 'Dream Pop', 40, 0, 40), -- LEAF
  (766, 'Dream Trance', 0, 0, 0), -- LEAF
  (767, 'Dreampunk', 1, 0, 1), -- LEAF
  (768, 'Dreamwave', 0, 0, 0), -- LEAF
  (769, 'Drift Phonk', 0, 2, 0), -- 2 children
  (770, 'Drill', 5, 9, 10), -- 9 children
  (771, 'Drill and Bass', 10, 0, 10), -- LEAF
  (772, 'Drinking Song', 0, 0, 0), -- LEAF
  (773, 'Drone', 69, 0, 69), -- LEAF
  (774, 'Drone Metal', 22, 0, 22), -- LEAF
  (775, 'Drum and Bass', 2, 25, 16), -- 25 children
  (776, 'Drum and Bugle Corps', 0, 0, 0), -- LEAF
  (777, 'Drumfunk', 1, 0, 1), -- LEAF
  (778, 'Drumless', 45, 0, 45), -- LEAF
  (779, 'Drumline', 0, 0, 0), -- LEAF
  (780, 'Drumstep', 0, 0, 0), -- LEAF
  (781, 'Druze Music', 0, 0, 0), -- LEAF
  (782, 'DSBM', 2, 0, 2), -- LEAF
  (783, 'Dub', 10, 0, 10), -- LEAF
  (784, 'Dub Poetry', 0, 0, 0), -- LEAF
  (785, 'Dub Techno', 1, 0, 1), -- LEAF
  (786, 'Dubstep', 2, 15, 8), -- 15 children
  (787, 'Dubstyle', 0, 0, 0), -- LEAF
  (788, 'Dubwise Drum and Bass', 0, 0, 0), -- LEAF
  (789, 'Duma', 0, 0, 0), -- LEAF
  (790, 'Dunedin Sound', 0, 0, 0), -- LEAF
  (791, 'Dungeon Rap', 1, 0, 1), -- LEAF
  (792, 'Dungeon Sound', 0, 0, 0), -- LEAF
  (793, 'Dungeon Synth', 3, 4, 6), -- 4 children
  (794, 'Duranguense', 0, 0, 0), -- LEAF
  (795, 'Dutch Cabaret', 0, 0, 0), -- LEAF
  (796, 'Dutch Folk Music', 0, 0, 0), -- LEAF
  (797, 'Dutch House', 0, 1, 0), -- 1 children
  (798, 'Düsseldorf School', 0, 0, 0), -- LEAF
  (799, 'EAI', 0, 0, 0), -- LEAF
  (800, 'Early Hardstyle', 0, 0, 0), -- LEAF
  (801, 'East African Music', 0, 32, 0), -- 32 children
  (802, 'East Asian Classical Music', 0, 27, 0), -- 27 children
  (803, 'East Asian Folk Music', 0, 28, 2), -- 28 children
  (804, 'East Asian Music', 0, 108, 2), -- 108 children
  (805, 'East Coast Club', 0, 3, 4), -- 3 children
  (806, 'East Coast Hip Hop', 9, 3, 9), -- 3 children
  (807, 'East Slavic Church Music', 0, 4, 0), -- 4 children
  (808, 'Eastern-Style Polka', 0, 0, 0), -- LEAF
  (809, 'Easy Listening', 1, 7, 10), -- 7 children
  (810, 'Easycore', 1, 0, 1), -- LEAF
  (811, 'EBM', 6, 6, 7), -- 6 children
  (812, 'Eccojams', 1, 0, 1), -- LEAF
  (813, 'ECM Style Jazz', 1, 0, 1), -- LEAF
  (814, 'Educational Music', 0, 0, 0), -- LEAF
  (815, 'Egg Punk', 0, 0, 0), -- LEAF
  (816, 'Egyptian Music', 0, 8, 0), -- 8 children
  (817, 'Electric Blues', 0, 4, 0), -- 4 children
  (818, 'Electric Texas Blues', 0, 0, 0), -- LEAF
  (819, 'Electro', 1, 0, 1), -- LEAF
  (820, 'Electro Hop', 0, 0, 0), -- LEAF
  (821, 'Electro House', 8, 6, 8), -- 6 children
  (822, 'Electro latino', 0, 0, 0), -- LEAF
  (823, 'Electro Swing', 0, 0, 0), -- LEAF
  (824, 'Electro Trance', 0, 0, 0), -- LEAF
  (825, 'Electro-Disco', 5, 6, 6), -- 6 children
  (826, 'Electro-Industrial', 26, 2, 26), -- 2 children
  (827, 'Electroacoustic', 10, 3, 29), -- 3 children
  (828, 'Electroclash', 8, 0, 8), -- LEAF
  (829, 'Electronic', 32, 418, 371), -- 418 children
  (830, 'Electronic Dance Music', 6, 324, 147), -- 324 children
  (831, 'Electronicore', 3, 0, 3), -- LEAF
  (832, 'Electropop', 16, 0, 16), -- LEAF
  (833, 'Electrotango', 0, 0, 0), -- LEAF
  (834, 'Eleki', 0, 0, 0), -- LEAF
  (835, 'Eletrofunk', 0, 0, 0), -- LEAF
  (836, 'Elizabethan Song', 0, 0, 0), -- LEAF
  (837, 'Embolada', 0, 0, 0), -- LEAF
  (838, 'Emo', 18, 6, 45), -- 6 children
  (839, 'Emo Rap', 7, 0, 7), -- LEAF
  (840, 'Emo Revival', 1, 0, 1), -- LEAF
  (841, 'Emo-Pop', 6, 0, 6), -- LEAF
  (842, 'Emocore', 1, 0, 1), -- LEAF
  (843, 'Emoviolence', 6, 0, 6), -- LEAF
  (844, 'English Folk Music', 1, 4, 1), -- 4 children
  (845, 'English Pastoral School', 0, 0, 0), -- LEAF
  (846, 'English Underground', 0, 1, 0), -- 1 children
  (847, 'Enka', 0, 0, 0), -- LEAF
  (848, 'Entechna', 0, 2, 0), -- 2 children
  (849, 'Entechna laika', 0, 0, 0), -- LEAF
  (850, 'Epadunk', 0, 0, 0), -- LEAF
  (851, 'Epic Collage', 7, 0, 7), -- LEAF
  (852, 'Epic Doom Metal', 1, 0, 1), -- LEAF
  (853, 'Epic Music', 0, 0, 0), -- LEAF
  (854, 'Estonian Folk Music', 0, 1, 0), -- 1 children
  (855, 'Ethereal Wave', 11, 0, 11), -- LEAF
  (856, 'Ethio-Jazz', 0, 0, 0), -- LEAF
  (857, 'Ethiopian Church Music', 0, 0, 0), -- LEAF
  (858, 'Ethiopic Music', 0, 7, 0), -- 7 children
  (859, 'Euphoric Hardstyle', 0, 0, 0), -- LEAF
  (860, 'Euro House', 1, 1, 1), -- 1 children
  (861, 'Euro Trance', 0, 2, 0), -- 2 children
  (862, 'Euro-Disco', 0, 0, 0), -- LEAF
  (863, 'Euro-Trance', 1, 0, 1), -- LEAF
  (864, 'Eurobeat', 0, 1, 0), -- 1 children
  (865, 'Eurodance', 0, 2, 0), -- 2 children
  (866, 'European Folk Music', 1, 183, 6), -- 183 children
  (867, 'European Free Jazz', 1, 0, 1), -- LEAF
  (868, 'European Music', 0, 366, 15), -- 366 children
  (869, 'Europop', 0, 0, 0), -- LEAF
  (870, 'Euskal kantagintza berria', 0, 0, 0), -- LEAF
  (871, 'Ewe Music', 0, 2, 0), -- 2 children
  (872, 'Exotica', 3, 1, 3), -- 1 children
  (873, 'Experimental', 22, 37, 247), -- 37 children
  (874, 'Experimental Big Band', 4, 0, 4), -- LEAF
  (875, 'Experimental Hip Hop', 116, 1, 129), -- 1 children
  (876, 'Experimental Rock', 73, 4, 111), -- 4 children
  (877, 'Expressionism', 0, 0, 0), -- LEAF
  (878, 'Extratone', 3, 0, 3), -- LEAF
  (879, 'Fado', 0, 1, 0), -- 1 children
  (880, 'Fado de Coimbra', 0, 0, 0), -- LEAF
  (881, 'Fairy Tale', 0, 0, 0), -- LEAF
  (882, 'Falak', 0, 0, 0), -- LEAF
  (883, 'Famo', 0, 0, 0), -- LEAF
  (884, 'Fandango', 0, 1, 0), -- 1 children
  (885, 'Fandango caiçara', 0, 0, 0), -- LEAF
  (886, 'Fanfare', 0, 0, 0), -- LEAF
  (887, 'Fantasia', 0, 0, 0), -- LEAF
  (888, 'Fantezi', 0, 0, 0), -- LEAF
  (889, 'Faroese Folk Music', 0, 0, 0), -- LEAF
  (890, 'Festejo', 0, 0, 0), -- LEAF
  (891, 'Festival Progressive House', 0, 0, 0), -- LEAF
  (892, 'Festival Trap', 0, 0, 0), -- LEAF
  (893, 'Fidget House', 2, 0, 2), -- LEAF
  (894, 'Field Hollers', 0, 0, 0), -- LEAF
  (896, 'Field Recordings', 25, 7, 34), -- 7 children
  (897, 'Fife and Drum Blues', 0, 0, 0), -- LEAF
  (898, 'Fife and Drum Corps', 0, 0, 0), -- LEAF
  (899, 'Fijian Music', 0, 1, 0), -- 1 children
  (900, 'Fijiri', 0, 0, 0), -- LEAF
  (901, 'Filin', 0, 0, 0), -- LEAF
  (902, 'Filk', 0, 0, 0), -- LEAF
  (903, 'Film Score', 0, 0, 0), -- LEAF
  (904, 'Film Soundtrack', 1, 2, 1), -- 2 children
  (905, 'Filmi', 0, 0, 0), -- LEAF
  (906, 'Finnish Folk Music', 0, 0, 0), -- LEAF
  (907, 'Finnish Tango', 0, 0, 0), -- LEAF
  (908, 'First Wave of Detroit Techno', 0, 0, 0), -- LEAF
  (909, 'Flamenco', 0, 4, 1), -- 4 children
  (910, 'Flamenco Jazz', 1, 0, 1), -- LEAF
  (911, 'Flamenco nuevo', 0, 1, 1), -- 1 children
  (912, 'Flamenco Pop', 0, 0, 0), -- LEAF
  (913, 'Flashcore', 2, 0, 2), -- LEAF
  (914, 'Flemish Folk Music', 0, 0, 0), -- LEAF
  (915, 'Flex Dance Music', 0, 0, 0), -- LEAF
  (916, 'Flint Sound', 0, 0, 0), -- LEAF
  (917, 'Florida Breaks', 0, 0, 0), -- LEAF
  (918, 'Florida Fast Music', 0, 0, 0), -- LEAF
  (919, 'FM Synthesis', 0, 0, 0), -- LEAF
  (920, 'Folk', 0, 468, 101), -- 468 children
  (921, 'Folk Baroque', 1, 0, 1), -- LEAF
  (922, 'Folk Metal', 3, 2, 3), -- 2 children
  (923, 'Folk Pop', 5, 1, 5), -- 1 children
  (924, 'Folk Punk', 5, 2, 6), -- 2 children
  (925, 'Folk Rock', 6, 8, 6), -- 8 children
  (926, 'Folkhop', 0, 0, 0), -- LEAF
  (927, 'Folklor miejski', 0, 1, 0), -- 1 children
  (928, 'Folktales', 0, 0, 0), -- LEAF
  (929, 'Folktronica', 12, 0, 12), -- LEAF
  (930, 'Fon leb', 0, 0, 0), -- LEAF
  (931, 'Fon Music', 0, 3, 0), -- 3 children
  (932, 'Football Chant', 0, 0, 0), -- LEAF
  (933, 'Footwork', 4, 1, 4), -- 1 children
  (934, 'Footwork Jungle', 0, 0, 0), -- LEAF
  (935, 'Forest Psytrance', 0, 0, 0), -- LEAF
  (936, 'Forró', 1, 4, 1), -- 4 children
  (937, 'Forró de favela', 0, 0, 0), -- LEAF
  (938, 'Forró eletrônico', 0, 2, 0), -- 2 children
  (939, 'Forró universitário', 0, 0, 0), -- LEAF
  (940, 'Fort Thunder Scene', 0, 0, 0), -- LEAF
  (941, 'Foxtrot', 0, 0, 0), -- LEAF
  (942, 'Franco-Flemish School', 0, 0, 0), -- LEAF
  (943, 'Frankfurt Sound', 0, 0, 0), -- LEAF
  (944, 'Frapcore', 0, 0, 0), -- LEAF
  (945, 'Frat Rap', 0, 0, 0), -- LEAF
  (946, 'Frat Rock', 0, 0, 0), -- LEAF
  (947, 'Freak Folk', 4, 0, 4), -- LEAF
  (948, 'Freakbeat', 0, 0, 0), -- LEAF
  (949, 'Free Car Music', 0, 0, 0), -- LEAF
  (950, 'Free Folk', 6, 0, 6), -- LEAF
  (951, 'Free Funk', 0, 0, 0), -- LEAF
  (952, 'Free Improvisation', 10, 2, 10), -- 2 children
  (953, 'Free Jazz', 12, 1, 12), -- 1 children
  (954, 'Free Noise', 0, 0, 0), -- LEAF
  (955, 'Freeform Hardcore', 0, 0, 0), -- LEAF
  (956, 'Freestyle', 1, 1, 1), -- 1 children
  (957, 'Freetekno', 0, 0, 0), -- LEAF
  (958, 'French Caribbean Music', 0, 20, 0), -- 20 children
  (959, 'French Electro', 2, 0, 2), -- LEAF
  (960, 'French Folk Music', 0, 13, 0), -- 13 children
  (961, 'French Hip Hop', 0, 0, 0), -- LEAF
  (962, 'French House', 4, 0, 4), -- LEAF
  (963, 'French Pop', 1, 0, 1), -- LEAF
  (964, 'French-Canadian Folk Music', 0, 0, 0), -- LEAF
  (965, 'Frenchcore', 1, 0, 1), -- LEAF
  (966, 'Frevo', 0, 4, 0), -- 4 children
  (967, 'Frevo de bloco', 0, 0, 0), -- LEAF
  (968, 'Frevo de rua', 0, 0, 0), -- LEAF
  (969, 'Frevo elétrico', 0, 0, 0), -- LEAF
  (970, 'Frevo-canção', 0, 0, 0), -- LEAF
  (971, 'Friese bries', 0, 0, 0), -- LEAF
  (972, 'Fugue', 0, 0, 0), -- LEAF
  (973, 'Fuji', 0, 0, 0), -- LEAF
  (974, 'Fula Music', 0, 0, 0), -- LEAF
  (975, 'Full-On Psytrance', 0, 0, 0), -- LEAF
  (976, 'Funaná', 0, 0, 0), -- LEAF
  (977, 'Funeral Doom Metal', 3, 0, 3), -- LEAF
  (978, 'Funeral March', 0, 0, 0), -- LEAF
  (979, 'Fungi', 0, 0, 0), -- LEAF
  (980, 'Funk', 26, 12, 58), -- 12 children
  (981, 'Funk 150 bpm', 0, 0, 0), -- LEAF
  (982, 'Funk automotivo', 0, 0, 0), -- LEAF
  (983, 'Funk brasileiro', 3, 25, 4), -- 25 children
  (984, 'Funk carioca', 0, 2, 2), -- 2 children
  (985, 'Funk consciente', 0, 0, 0), -- LEAF
  (986, 'Funk de BH', 0, 0, 0), -- LEAF
  (987, 'Funk mandelão', 1, 4, 1), -- 4 children
  (988, 'Funk Melody', 0, 0, 0), -- LEAF
  (989, 'Funk Metal', 3, 0, 3), -- LEAF
  (990, 'Funk ostentação', 0, 0, 0), -- LEAF
  (991, 'Funk proibidão', 0, 0, 0), -- LEAF
  (992, 'Funk Rock', 17, 1, 20), -- 1 children
  (993, 'Funknejo', 0, 0, 0), -- LEAF
  (994, 'Funkot', 0, 2, 0), -- 2 children
  (995, 'Funktronica', 1, 0, 1), -- LEAF
  (996, 'Funky Breaks', 0, 0, 0), -- LEAF
  (997, 'Funky House', 1, 0, 1), -- LEAF
  (998, 'Furry Music', 0, 0, 0), -- LEAF
  (999, 'Fusion Gugak', 0, 0, 0), -- LEAF
  (1000, 'Future Bass', 4, 2, 4), -- 2 children
  (1001, 'Future Bounce', 0, 0, 0), -- LEAF
  (1002, 'Future Core', 0, 0, 0), -- LEAF
  (1003, 'Future Funk', 0, 0, 0), -- LEAF
  (1004, 'Future Garage', 3, 0, 3), -- LEAF
  (1005, 'Future House', 0, 2, 0), -- 2 children
  (1006, 'Future Rave', 0, 0, 0), -- LEAF
  (1007, 'Future Riddim', 2, 0, 2), -- LEAF
  (1008, 'Futurepop', 1, 0, 1), -- LEAF
  (1009, 'Futurism', 0, 0, 0), -- LEAF
  (1010, 'Futuristic Swag', 0, 0, 0), -- LEAF
  (1011, 'G-Funk', 2, 0, 2), -- LEAF
  (1012, 'G-House', 0, 0, 0), -- LEAF
  (1013, 'Gaana', 0, 0, 0), -- LEAF
  (1014, 'Gabber', 3, 1, 3), -- 1 children
  (1015, 'Gagaku', 0, 0, 0), -- LEAF
  (1016, 'Gagauz Folk Music', 0, 0, 0), -- LEAF
  (1017, 'Gagok', 0, 0, 0), -- LEAF
  (1018, 'Gaita zuliana', 0, 0, 0), -- LEAF
  (1019, 'Galician Folk Music', 0, 0, 0), -- LEAF
  (1020, 'Gallican Chant', 0, 0, 0), -- LEAF
  (1021, 'Gambang kromong', 0, 0, 0), -- LEAF
  (1022, 'Gamelan', 0, 14, 0), -- 14 children
  (1023, 'Gamelan (Indonesian)', 1, 0, 1), -- LEAF
  (1024, 'Gamelan angklung', 0, 0, 0), -- LEAF
  (1025, 'Gamelan beleganjur', 0, 0, 0), -- LEAF
  (1026, 'Gamelan degung', 0, 0, 0), -- LEAF
  (1027, 'Gamelan gender wayang', 0, 0, 0), -- LEAF
  (1028, 'Gamelan gong gede', 0, 0, 0), -- LEAF
  (1029, 'Gamelan gong kebyar', 0, 0, 0), -- LEAF
  (1030, 'Gamelan jegog', 0, 0, 0), -- LEAF
  (1031, 'Gamelan sekaten', 0, 0, 0), -- LEAF
  (1032, 'Gamelan selonding', 0, 0, 0), -- LEAF
  (1033, 'Gamelan semar pegulingan', 0, 0, 0), -- LEAF
  (1034, 'Ganga', 0, 0, 0), -- LEAF
  (1035, 'Gangsta Rap', 36, 5, 37), -- 5 children
  (1036, 'Garage House', 1, 2, 1), -- 2 children
  (1037, 'Garage Psych', 1, 0, 1), -- LEAF
  (1038, 'Garage Punk', 8, 0, 8), -- LEAF
  (1039, 'Garage Rock', 6, 6, 12), -- 6 children
  (1040, 'Garage Rock Revival', 1, 0, 1), -- LEAF
  (1041, 'Garba', 0, 0, 0), -- LEAF
  (1042, 'Garifuna Folk Music', 0, 1, 0), -- 1 children
  (1043, 'Gascon Folk Music', 0, 0, 0), -- LEAF
  (1044, 'Geek Rock', 1, 0, 1), -- LEAF
  (1045, 'Genge', 0, 1, 0), -- 1 children
  (1046, 'Gengetone', 0, 0, 0), -- LEAF
  (1047, 'Georgian Folk Music', 0, 1, 0), -- 1 children
  (1048, 'German Folk Music', 0, 2, 0), -- 2 children
  (1049, 'German Music', 0, 12, 1), -- 12 children
  (1050, 'Ghazal', 1, 0, 1), -- LEAF
  (1051, 'Ghetto Funk', 0, 0, 0), -- LEAF
  (1052, 'Ghetto House', 0, 1, 2), -- 1 children
  (1053, 'Ghettotech', 2, 0, 2), -- LEAF
  (1054, 'Ghost Dance Song', 0, 0, 0), -- LEAF
  (1055, 'Gilaki Music', 0, 0, 0), -- LEAF
  (1056, 'Ginan', 0, 0, 0), -- LEAF
  (1057, 'Girl Group', 0, 0, 0), -- LEAF
  (1058, 'Glam Metal', 0, 1, 0), -- 1 children
  (1059, 'Glam Punk', 0, 0, 0), -- LEAF
  (1060, 'Glam Rock', 7, 1, 7), -- 1 children
  (1061, 'Glitch', 46, 0, 46), -- LEAF
  (1062, 'Glitch Hop', 24, 0, 24), -- LEAF
  (1063, 'Glitch Hop [EDM]', 0, 2, 0), -- 2 children
  (1064, 'Glitch Pop', 26, 0, 26), -- LEAF
  (1065, 'Gnawa', 0, 0, 0), -- LEAF
  (1066, 'Go-Go', 0, 1, 0), -- 1 children
  (1067, 'Goa Trance', 0, 1, 0), -- 1 children
  (1068, 'Goan Music', 0, 0, 0), -- LEAF
  (1069, 'Gogo Music', 0, 0, 0), -- LEAF
  (1070, 'Gommance', 0, 0, 0), -- LEAF
  (1071, 'Gondang', 0, 0, 0), -- LEAF
  (1072, 'Goombay', 1, 0, 1), -- LEAF
  (1073, 'Goral Music', 0, 1, 0), -- 1 children
  (1074, 'Goregrind', 15, 2, 17), -- 2 children
  (1075, 'Gorenoise', 7, 0, 7), -- LEAF
  (1076, 'Gospel', 5, 8, 5), -- 8 children
  (1077, 'Gospel House', 0, 0, 0), -- LEAF
  (1078, 'Gothenburg Sound', 0, 0, 0), -- LEAF
  (1079, 'Gothic Country', 2, 0, 2), -- LEAF
  (1080, 'Gothic Metal', 4, 0, 4), -- LEAF
  (1081, 'Gothic Rock', 17, 2, 20), -- 2 children
  (1082, 'Gqom', 0, 0, 0), -- LEAF
  (1083, 'Grand opéra', 0, 0, 0), -- LEAF
  (1084, 'Graphical Sound', 0, 0, 0), -- LEAF
  (1085, 'Grebo', 0, 0, 0), -- LEAF
  (1086, 'Greek Folk Music', 0, 6, 0), -- 6 children
  (1087, 'Greek Music', 0, 16, 1), -- 16 children
  (1088, 'Greenlandic Music', 0, 4, 0), -- 4 children
  (1089, 'Greenwich Village Scene', 0, 0, 0), -- LEAF
  (1090, 'Gregorian Chant', 1, 1, 1), -- 1 children
  (1091, 'Grime', 2, 2, 2), -- 2 children
  (1092, 'Grindcore', 36, 7, 64), -- 7 children
  (1093, 'Griot Music', 0, 0, 0), -- LEAF
  (1094, 'Groove Metal', 0, 0, 0), -- LEAF
  (1095, 'Group Sounds', 0, 0, 0), -- LEAF
  (1096, 'Grunge', 8, 0, 8), -- LEAF
  (1097, 'Gstanzl', 0, 0, 0), -- LEAF
  (1098, 'Guaguancó', 0, 0, 0), -- LEAF
  (1099, 'Guajira', 0, 0, 0), -- LEAF
  (1100, 'Guangdong yinyue', 0, 0, 0), -- LEAF
  (1101, 'Guaracha', 0, 0, 0), -- LEAF
  (1102, 'Guaracha [EDM]', 0, 0, 0), -- LEAF
  (1103, 'Guaracha santiagueña', 0, 0, 0), -- LEAF
  (1104, 'Guarania', 0, 0, 0), -- LEAF
  (1105, 'Gufeng', 0, 0, 0), -- LEAF
  (1106, 'Guggenmusik', 0, 0, 0), -- LEAF
  (1107, 'Guided Meditation', 0, 0, 0), -- LEAF
  (1108, 'Guitarrada', 0, 0, 0), -- LEAF
  (1109, 'Gujarati Folk Music', 0, 0, 0), -- LEAF
  (1110, 'Gumbe', 0, 0, 0), -- LEAF
  (1111, 'Gurage Music', 0, 0, 0), -- LEAF
  (1112, 'Gwo ka', 0, 0, 0), -- LEAF
  (1113, 'Gypsy Punk', 2, 0, 2), -- LEAF
  (1114, 'Género chico', 0, 0, 0), -- LEAF
  (1115, 'Għana', 0, 0, 0), -- LEAF
  (1116, 'H8000', 0, 0, 0), -- LEAF
  (1117, 'Habanera', 0, 0, 0), -- LEAF
  (1118, 'Haight-Ashbury Scene', 0, 0, 0), -- LEAF
  (1119, 'Haitian Music', 0, 8, 0), -- 8 children
  (1120, 'Haitian Vodou Drumming', 0, 0, 0), -- LEAF
  (1121, 'Halftime', 1, 0, 1), -- LEAF
  (1122, 'Halloween Music', 0, 0, 0), -- LEAF
  (1123, 'Hambo', 0, 0, 0), -- LEAF
  (1124, 'Hamburger Schule', 0, 0, 0), -- LEAF
  (1125, 'Han Folk Music', 0, 0, 0), -- LEAF
  (1126, 'Hands Up', 0, 1, 0), -- 1 children
  (1127, 'Hanmai', 0, 0, 0), -- LEAF
  (1128, 'Haozi', 0, 0, 0), -- LEAF
  (1129, 'Hapa haole', 0, 0, 0), -- LEAF
  (1130, 'Happy Hardcore', 2, 4, 2), -- 4 children
  (1131, 'Happy Rock', 0, 0, 0), -- LEAF
  (1132, 'Harana', 0, 0, 0), -- LEAF
  (1133, 'Harawi', 0, 0, 0), -- LEAF
  (1134, 'Hard Beat', 0, 0, 0), -- LEAF
  (1135, 'Hard Bop', 5, 0, 5), -- LEAF
  (1136, 'Hard Dance', 1, 23, 2), -- 23 children
  (1137, 'Hard Drum', 2, 0, 2), -- LEAF
  (1138, 'Hard Rock', 2, 6, 14), -- 6 children
  (1139, 'Hard Techno', 0, 1, 0), -- 1 children
  (1140, 'Hard Trance', 1, 0, 1), -- LEAF
  (1141, 'Hard Trap', 0, 0, 0), -- LEAF
  (1142, 'Hardbag', 0, 0, 0), -- LEAF
  (1143, 'Hardbass', 0, 0, 0), -- LEAF
  (1144, 'Hardcore [EDM]', 0, 35, 31), -- 35 children
  (1145, 'Hardcore [Punk]', 0, 41, 164), -- 41 children
  (1146, 'Hardcore Breaks', 1, 0, 1), -- LEAF
  (1147, 'Hardcore Hip Hop', 46, 14, 91), -- 14 children
  (1148, 'Hardcore Punk', 10, 16, 42), -- 16 children
  (1149, 'Hardgroove Techno', 2, 0, 2), -- LEAF
  (1150, 'Hardline', 0, 0, 0), -- LEAF
  (1151, 'Hardstep', 0, 0, 0), -- LEAF
  (1152, 'Hardstyle', 1, 8, 1), -- 8 children
  (1153, 'Hardtek', 0, 1, 0), -- 1 children
  (1154, 'Hardtekk', 0, 0, 0), -- LEAF
  (1155, 'Hardvapour', 1, 0, 1), -- LEAF
  (1156, 'Hardwave', 0, 0, 0), -- LEAF
  (1157, 'Harlem Renaissance', 0, 0, 0), -- LEAF
  (1158, 'Harsh Noise', 42, 1, 45), -- 1 children
  (1159, 'Harsh Noise Wall', 4, 0, 4), -- LEAF
  (1160, 'Hasidic Music', 0, 1, 0), -- 1 children
  (1161, 'Hauntology', 3, 0, 3), -- LEAF
  (1162, 'Hausa Music', 0, 0, 0), -- LEAF
  (1163, 'Hawaiian Music', 0, 3, 0), -- 3 children
  (1164, 'Hazara Folk Music', 0, 0, 0), -- LEAF
  (1165, 'Heartland Rock', 0, 0, 0), -- LEAF
  (1166, 'Heaven Trap', 0, 0, 0), -- LEAF
  (1167, 'Heavy Metal', 3, 2, 4), -- 2 children
  (1168, 'Heavy Psych', 9, 0, 9), -- LEAF
  (1169, 'Heikyoku', 0, 0, 0), -- LEAF
  (1170, 'Hellenic Black Metal', 0, 0, 0), -- LEAF
  (1171, 'Henan Opera', 0, 0, 0), -- LEAF
  (1172, 'HexD', 1, 1, 1), -- 1 children
  (1173, 'Hi-NRG', 2, 0, 2), -- LEAF
  (1174, 'Hi-Tech Full-On', 0, 0, 0), -- LEAF
  (1175, 'Hi-Tech Psytrance', 1, 0, 1), -- LEAF
  (1176, 'High Quality Rip', 0, 0, 0), -- LEAF
  (1177, 'Highlife', 0, 1, 0), -- 1 children
  (1178, 'Hill Country Blues', 0, 0, 0), -- LEAF
  (1179, 'Hill Tribe Music', 0, 3, 0), -- 3 children
  (1180, 'Himene tarava', 0, 0, 0), -- LEAF
  (1181, 'Hindustani Classical Music', 3, 8, 5), -- 8 children
  (1182, 'Hip Hop', 8, 109, 241), -- 109 children
  (1183, 'Hip Hop Soul', 3, 0, 3), -- LEAF
  (1184, 'Hip House', 4, 0, 4), -- LEAF
  (1185, 'Hip-hopolo', 0, 0, 0), -- LEAF
  (1186, 'Hipco', 0, 0, 0), -- LEAF
  (1187, 'Hiplife', 0, 0, 0), -- LEAF
  (1188, 'Hispanic American Folk Music', 0, 39, 0), -- 39 children
  (1189, 'Hispanic American Music', 0, 197, 5), -- 197 children
  (1190, 'Hispanic Music', 0, 236, 6), -- 236 children
  (1191, 'Hmong Folk Music', 0, 0, 0), -- LEAF
  (1192, 'Hmong Pop', 0, 0, 0), -- LEAF
  (1193, 'Hoboken Sound', 0, 0, 0), -- LEAF
  (1194, 'Hokkien Pop', 0, 0, 0), -- LEAF
  (1195, 'Holiday Music', 0, 7, 0), -- 7 children
  (1196, 'Hollandse School', 0, 0, 0), -- LEAF
  (1197, 'Holy Minimalism', 0, 0, 0), -- LEAF
  (1198, 'Holy Terror', 0, 0, 0), -- LEAF
  (1199, 'Honky Tonk', 0, 2, 0), -- 2 children
  (1200, 'Honky-Tonk Piano', 0, 0, 0), -- LEAF
  (1201, 'Honkyoku', 0, 0, 0), -- LEAF
  (1202, 'Hornpipe', 0, 0, 0), -- LEAF
  (1203, 'Horror Punk', 0, 0, 0), -- LEAF
  (1204, 'Horror Synth', 2, 0, 2), -- LEAF
  (1205, 'Horrorcore', 12, 0, 12), -- LEAF
  (1206, 'Hot Rod Music', 0, 0, 0), -- LEAF
  (1207, 'House', 5, 72, 33), -- 72 children
  (1208, 'Houston Sound', 0, 0, 0), -- LEAF
  (1209, 'Huaylarsh', 0, 0, 0), -- LEAF
  (1210, 'Huayno', 0, 5, 0), -- 5 children
  (1211, 'Humppa', 0, 0, 0), -- LEAF
  (1212, 'Hungarian Folk Music', 0, 3, 0), -- 3 children
  (1213, 'Hutsul Folk Music', 0, 0, 0), -- LEAF
  (1214, 'Hyang-ak', 0, 0, 0), -- LEAF
  (1215, 'Hybrid Trap', 2, 0, 2), -- LEAF
  (1216, 'Hymn', 0, 5, 0), -- 5 children
  (1217, 'Hymns', 1, 0, 1), -- LEAF
  (1218, 'Hyper Techno', 0, 0, 0), -- LEAF
  (1219, 'Hyperpop', 6, 0, 6), -- LEAF
  (1220, 'Hypertechno', 0, 0, 0), -- LEAF
  (1221, 'Hyphy', 1, 1, 1), -- 1 children
  (1222, 'Hypnagogic Pop', 25, 0, 25), -- LEAF
  (1223, 'Hát lô tô', 0, 0, 0), -- LEAF
  (1224, 'Hưng ca', 0, 0, 0), -- LEAF
  (1225, 'Iberian Music', 0, 52, 1), -- 52 children
  (1226, 'Ibiza Trance', 0, 0, 0), -- LEAF
  (1227, 'Icelandic Folk Music', 1, 0, 1), -- LEAF
  (1228, 'IDM', 38, 1, 44), -- 1 children
  (1229, 'Idol kayō', 1, 0, 1), -- LEAF
  (1230, 'Igbo Music', 0, 1, 0), -- 1 children
  (1231, 'Igorot Music', 0, 0, 0), -- LEAF
  (1232, 'Illbient', 7, 0, 7), -- LEAF
  (1233, 'Ilocano Music', 0, 0, 0), -- LEAF
  (1234, 'Impressionism', 3, 0, 3), -- LEAF
  (1235, 'Impromptu', 0, 0, 0), -- LEAF
  (1236, 'Indeterminacy', 0, 0, 0), -- LEAF
  (1237, 'Indian Pop', 0, 1, 0), -- 1 children
  (1238, 'Indie Folk', 30, 1, 30), -- 1 children
  (1239, 'Indie Pop', 18, 7, 38), -- 7 children
  (1241, 'Indie Rock', 55, 16, 113), -- 16 children
  (1242, 'Indie Sleaze Revival', 0, 0, 0), -- LEAF
  (1243, 'Indie Surf', 3, 0, 3), -- LEAF
  (1244, 'Indietronica', 35, 4, 59), -- 4 children
  (1245, 'Indigenous American Music', 0, 37, 1), -- 37 children
  (1246, 'Indigenous American Traditional Music', 0, 9, 1), -- 9 children
  (1247, 'Indigenous Andean Music', 0, 11, 0), -- 11 children
  (1248, 'Indigenous Australian Traditional Music', 1, 2, 1), -- 2 children
  (1249, 'Indigenous North American Music', 0, 15, 1), -- 15 children
  (1250, 'Indigenous Taiwanese Music', 0, 0, 0), -- LEAF
  (1251, 'Indo Jazz', 1, 0, 1), -- LEAF
  (1252, 'Indo-Caribbean Music', 0, 4, 0), -- 4 children
  (1253, 'Indonesian Music', 0, 43, 0), -- 43 children
  (1254, 'Indorock', 0, 0, 0), -- LEAF
  (1255, 'Industrial', 26, 2, 59), -- 2 children
  (1256, 'Industrial & Noise', 0, 33, 245), -- 33 children
  (1257, 'Industrial Folk Song', 1, 0, 1), -- LEAF
  (1258, 'Industrial Hardcore', 4, 0, 4), -- LEAF
  (1259, 'Industrial Hip Hop', 31, 0, 31), -- LEAF
  (1260, 'Industrial Metal', 19, 2, 20), -- 2 children
  (1261, 'Industrial Rock', 24, 1, 24), -- 1 children
  (1262, 'Industrial Techno', 12, 1, 13), -- 1 children
  (1263, 'Inkiranya', 0, 0, 0), -- LEAF
  (1264, 'Insect Sounds', 2, 0, 2), -- LEAF
  (1265, 'Instrumental', 1, 0, 1), -- LEAF
  (1266, 'Instrumental Hip Hop', 12, 1, 12), -- 1 children
  (1267, 'Integral Serialism', 0, 0, 0), -- LEAF
  (1268, 'Interview', 3, 0, 3), -- LEAF
  (1269, 'Inuit Music', 0, 3, 1), -- 3 children
  (1270, 'Inuit Vocal Games', 1, 0, 1), -- LEAF
  (1271, 'Ionian Islands Folk Music', 0, 0, 0), -- LEAF
  (1272, 'Iraqi Maqam', 0, 0, 0), -- LEAF
  (1273, 'Irish Folk Music', 0, 1, 0), -- 1 children
  (1274, 'Irish Showband', 0, 0, 0), -- LEAF
  (1275, 'Isicathamiya', 0, 0, 0), -- LEAF
  (1276, 'Islamic Religious Music & Recitation', 0, 9, 0), -- 9 children
  (1277, 'Israeli Folk Music', 0, 0, 0), -- LEAF
  (1278, 'Istrian Folk Music', 0, 0, 0), -- LEAF
  (1279, 'Italian Folk Music', 0, 11, 0), -- 11 children
  (1280, 'Italian Music', 0, 19, 1), -- 19 children
  (1281, 'Italo Dance', 0, 0, 0), -- LEAF
  (1282, 'Italo House', 0, 0, 0), -- LEAF
  (1283, 'Italo Pop', 0, 1, 0), -- 1 children
  (1284, 'Italo-Disco', 0, 2, 0), -- 2 children
  (1285, 'Izlan', 0, 0, 0), -- LEAF
  (1286, 'Izvorna bosanska muzika', 0, 0, 0), -- LEAF
  (1287, 'J-core', 0, 2, 0), -- 2 children
  (1288, 'J-Euro', 0, 0, 0), -- LEAF
  (1289, 'J-Pop', 5, 6, 5), -- 6 children
  (1290, 'J-Rock', 2, 0, 2), -- LEAF
  (1291, 'Jackin'' House', 0, 0, 0), -- LEAF
  (1292, 'Jaipongan', 0, 0, 0), -- LEAF
  (1293, 'Jam Band', 3, 2, 3), -- 2 children
  (1294, 'Jamaican Music', 0, 25, 13), -- 25 children
  (1295, 'Jamaican Ska', 0, 0, 0), -- LEAF
  (1296, 'James Bay Fiddling', 0, 0, 0), -- LEAF
  (1297, 'Jamgrass', 0, 0, 0), -- LEAF
  (1298, 'Jangle Pop', 6, 4, 6), -- 4 children
  (1299, 'Japanese Classical Music', 0, 12, 0), -- 12 children
  (1300, 'Japanese Folk Music', 1, 8, 1), -- 8 children
  (1301, 'Japanese Hardcore', 2, 0, 2), -- LEAF
  (1302, 'Japanese Hip Hop', 1, 0, 1), -- LEAF
  (1303, 'Japanese Idol', 0, 1, 0), -- 1 children
  (1304, 'Japanese Music', 0, 24, 1), -- 24 children
  (1305, 'Javanese Gamelan', 0, 2, 0), -- 2 children
  (1306, 'Javanese Music', 0, 8, 0), -- 8 children
  (1307, 'Jawaiian', 0, 0, 0), -- LEAF
  (1308, 'Jazz', 0, 53, 78), -- 53 children
  (1309, 'Jazz Fusion', 38, 0, 38), -- LEAF
  (1310, 'Jazz guachaca', 0, 0, 0), -- LEAF
  (1311, 'Jazz manouche', 0, 0, 0), -- LEAF
  (1312, 'Jazz Mugham', 0, 0, 0), -- LEAF
  (1313, 'Jazz Poetry', 3, 0, 3), -- LEAF
  (1314, 'Jazz Pop', 14, 0, 14), -- LEAF
  (1315, 'Jazz Rap', 76, 0, 76), -- LEAF
  (1316, 'Jazz-Funk', 16, 1, 16), -- 1 children
  (1317, 'Jazz-Rock', 33, 0, 33), -- LEAF
  (1318, 'Jazzstep', 2, 0, 2), -- LEAF
  (1319, 'Jeong-ak', 0, 1, 0), -- 1 children
  (1320, 'Jerk', 2, 0, 2), -- LEAF
  (1321, 'Jerk Rap', 0, 0, 0), -- LEAF
  (1322, 'Jersey Club', 3, 0, 3), -- LEAF
  (1323, 'Jersey Club Rap', 0, 1, 0), -- 1 children
  (1324, 'Jersey Drill', 0, 0, 0), -- LEAF
  (1325, 'Jersey Shore Sound', 0, 0, 0), -- LEAF
  (1326, 'Jersey Sound', 0, 0, 0), -- LEAF
  (1327, 'Jesus Music', 0, 0, 0), -- LEAF
  (1328, 'Jewish Liturgical Music', 0, 7, 0), -- 7 children
  (1329, 'Jewish Music', 0, 22, 1), -- 22 children
  (1330, 'Jiangnan sizhu', 0, 0, 0), -- LEAF
  (1331, 'Jibaro', 0, 0, 0), -- LEAF
  (1332, 'Jigg', 0, 0, 0), -- LEAF
  (1333, 'Jilala Music', 0, 0, 0), -- LEAF
  (1334, 'Jingles', 2, 0, 2), -- LEAF
  (1335, 'Jit', 0, 0, 0), -- LEAF
  (1336, 'Jiuta', 0, 0, 0), -- LEAF
  (1337, 'Joik', 0, 0, 0), -- LEAF
  (1338, 'Jongo', 0, 1, 0), -- 1 children
  (1339, 'Jook', 0, 0, 0), -- LEAF
  (1340, 'Joropo', 0, 0, 0), -- LEAF
  (1341, 'Jovem Guarda', 0, 0, 0), -- LEAF
  (1342, 'Jubilee', 0, 0, 0), -- LEAF
  (1343, 'Jug Band', 0, 0, 0), -- LEAF
  (1344, 'Juke', 2, 0, 2), -- LEAF
  (1345, 'Jump Blues', 0, 0, 0), -- LEAF
  (1346, 'Jump-Up', 0, 0, 0), -- LEAF
  (1347, 'Jumpstyle', 1, 0, 1), -- LEAF
  (1348, 'Jungle', 1, 1, 1), -- 1 children
  (1349, 'Jungle Dutch', 0, 0, 0), -- LEAF
  (1350, 'Jungle Terror', 0, 0, 0), -- LEAF
  (1351, 'Junkanoo', 1, 0, 1), -- LEAF
  (1352, 'Jùjú', 0, 0, 0), -- LEAF
  (1353, 'Jōruri', 0, 0, 0), -- LEAF
  (1354, 'K-Pop', 0, 1, 0), -- 1 children
  (1355, 'Kabarett', 0, 0, 0), -- LEAF
  (1356, 'Kabye Folk Music', 0, 0, 0), -- LEAF
  (1357, 'Kabyle Music', 0, 0, 0), -- LEAF
  (1358, 'Kacapi suling', 0, 0, 0), -- LEAF
  (1359, 'Kadongo kamu', 0, 0, 0), -- LEAF
  (1360, 'Kafi', 0, 0, 0), -- LEAF
  (1361, 'Kagura', 0, 0, 0), -- LEAF
  (1362, 'Kai', 0, 0, 0), -- LEAF
  (1363, 'Kaiso', 0, 0, 0), -- LEAF
  (1364, 'Kakawin', 0, 0, 0), -- LEAF
  (1365, 'Kalattut', 0, 0, 0), -- LEAF
  (1366, 'Kalindula', 0, 0, 0), -- LEAF
  (1367, 'Kalmyk Music', 0, 0, 0), -- LEAF
  (1368, 'Kalon''ny fahiny', 0, 0, 0), -- LEAF
  (1369, 'Kan ha diskan', 0, 0, 0), -- LEAF
  (1370, 'Kaneka', 0, 0, 0), -- LEAF
  (1371, 'Kannada Folk Music', 0, 0, 0), -- LEAF
  (1372, 'Kansai No Wave', 0, 0, 0), -- LEAF
  (1373, 'Kantan Chamorrita', 0, 0, 0), -- LEAF
  (1374, 'Kanto', 0, 0, 0), -- LEAF
  (1375, 'Kantruem', 0, 0, 0), -- LEAF
  (1376, 'Kapuka', 0, 0, 0), -- LEAF
  (1377, 'Karachay-Balkarian Music', 0, 0, 0), -- LEAF
  (1378, 'Karakalpak Traditional Music', 0, 0, 0), -- LEAF
  (1379, 'Karelian Folk Music', 0, 0, 0), -- LEAF
  (1380, 'Kaseko', 0, 0, 0), -- LEAF
  (1381, 'Kashubian Folk Music', 0, 0, 0), -- LEAF
  (1382, 'Kawaii Future Bass', 1, 1, 1), -- 1 children
  (1383, 'Kawaii Metal', 0, 0, 0), -- LEAF
  (1384, 'Kayōkyoku', 1, 3, 1), -- 3 children
  (1385, 'Kazakh Music', 0, 0, 0), -- LEAF
  (1386, 'Kecak', 0, 0, 0), -- LEAF
  (1387, 'Kef Music', 0, 0, 0), -- LEAF
  (1388, 'Keller Synth', 0, 0, 0), -- LEAF
  (1389, 'Keroncong', 0, 2, 0), -- 2 children
  (1390, 'Kete', 0, 0, 0), -- LEAF
  (1391, 'Ketuk tilu', 0, 0, 0), -- LEAF
  (1392, 'Khakas Traditional Music', 0, 0, 0), -- LEAF
  (1393, 'Khaliji Music', 0, 8, 0), -- 8 children
  (1394, 'Khayal', 1, 0, 1), -- LEAF
  (1395, 'Khmer Folk Music', 0, 0, 0), -- LEAF
  (1396, 'Khmer Music', 0, 5, 0), -- 5 children
  (1397, 'Khoisan Folk Music', 0, 0, 0), -- LEAF
  (1398, 'Khrueang sai', 0, 0, 0), -- LEAF
  (1399, 'Kidandali', 0, 0, 0), -- LEAF
  (1400, 'Kidumbak', 0, 0, 0), -- LEAF
  (1401, 'Kilapanga', 0, 0, 0), -- LEAF
  (1402, 'Kirtan', 0, 1, 0), -- 1 children
  (1403, 'Kitchen Dance Music', 0, 0, 0), -- LEAF
  (1404, 'Kizomba', 0, 1, 0), -- 1 children
  (1405, 'Klapa', 0, 0, 0), -- LEAF
  (1406, 'Klasik', 0, 0, 0), -- LEAF
  (1407, 'Kleinkunst', 0, 0, 0), -- LEAF
  (1408, 'Klezmer', 1, 0, 1), -- LEAF
  (1409, 'Kliningan', 0, 0, 0), -- LEAF
  (1410, 'Koche bazari', 0, 0, 0), -- LEAF
  (1411, 'Komi Folk Music', 0, 0, 0), -- LEAF
  (1412, 'Konnakol', 0, 0, 0), -- LEAF
  (1413, 'Korean Ballad', 0, 1, 0), -- 1 children
  (1414, 'Korean Classical Music', 0, 5, 0), -- 5 children
  (1415, 'Korean Folk Music', 0, 5, 0), -- 5 children
  (1416, 'Korean Music', 0, 20, 0), -- 20 children
  (1417, 'Korean Revolutionary Opera', 0, 0, 0), -- LEAF
  (1418, 'Kote kei', 0, 0, 0), -- LEAF
  (1419, 'Kouta', 0, 0, 0), -- LEAF
  (1420, 'Krakowiak', 0, 0, 0), -- LEAF
  (1421, 'Krautrock', 22, 0, 22), -- LEAF
  (1422, 'Krishnacore', 0, 0, 0), -- LEAF
  (1423, 'Kriyat haTorah', 0, 0, 0), -- LEAF
  (1424, 'Kru Music', 0, 3, 0), -- 3 children
  (1425, 'Krushclub', 0, 0, 0), -- LEAF
  (1426, 'Kréyol djaz', 0, 0, 0), -- LEAF
  (1427, 'Kuda kepang', 0, 0, 0), -- LEAF
  (1428, 'Kuduro', 0, 1, 0), -- 1 children
  (1429, 'Kujawiak', 0, 0, 0), -- LEAF
  (1430, 'Kujon', 0, 0, 0), -- LEAF
  (1431, 'Kulintang', 0, 0, 0), -- LEAF
  (1432, 'Kumina', 0, 0, 0), -- LEAF
  (1433, 'Kumiuta', 0, 0, 0), -- LEAF
  (1434, 'Kundiman', 0, 0, 0), -- LEAF
  (1435, 'Kunqu Opera', 0, 0, 0), -- LEAF
  (1436, 'Kurdish Music', 0, 0, 0), -- LEAF
  (1437, 'Kurpian Folk Music', 0, 0, 0), -- LEAF
  (1438, 'Kwaito', 0, 1, 0), -- 1 children
  (1439, 'Kwassa kwassa', 0, 0, 0), -- LEAF
  (1440, 'Kwela', 0, 0, 0), -- LEAF
  (1441, 'Kyivan Chant', 0, 0, 0), -- LEAF
  (1442, 'Kyrgyz Traditional Music', 0, 0, 0), -- LEAF
  (1443, 'Könsrock', 1, 0, 1), -- LEAF
  (1444, 'LA Beat Scene', 0, 0, 0), -- LEAF
  (1445, 'LA Hard House', 0, 0, 0), -- LEAF
  (1446, 'Lab Polyphony', 0, 0, 0), -- LEAF
  (1447, 'Ladbroke Grove Scene', 0, 0, 0), -- LEAF
  (1448, 'Ladino Folksong', 0, 0, 0), -- LEAF
  (1449, 'Laika', 0, 3, 0), -- 3 children
  (1450, 'Lambada', 0, 1, 0), -- 1 children
  (1451, 'Landó', 0, 0, 0), -- LEAF
  (1452, 'Langgam Jawa', 0, 0, 0), -- LEAF
  (1453, 'Lao Folk Music', 0, 0, 0), -- LEAF
  (1454, 'Latin Alternative', 1, 1, 1), -- 1 children
  (1455, 'Latin American Classical Music', 0, 0, 0), -- LEAF
  (1456, 'Latin Disco', 0, 0, 0), -- LEAF
  (1457, 'Latin Electronic', 2, 6, 2), -- 6 children
  (1458, 'Latin Freestyle', 0, 0, 0), -- LEAF
  (1459, 'Latin Funk', 0, 0, 0), -- LEAF
  (1460, 'Latin House', 0, 0, 0), -- LEAF
  (1461, 'Latin Jazz', 1, 2, 1), -- 2 children
  (1462, 'Latin Pop', 0, 2, 0), -- 2 children
  (1463, 'Latin Rap', 0, 1, 0), -- 1 children
  (1464, 'Latin Rock', 1, 0, 1), -- LEAF
  (1465, 'Latin Soul', 0, 0, 0), -- LEAF
  (1466, 'Latvian Folk Music', 0, 0, 0), -- LEAF
  (1467, 'Lauda', 0, 0, 0), -- LEAF
  (1468, 'Laurel Canyon Scene', 0, 0, 0), -- LEAF
  (1469, 'Lavani', 0, 0, 0), -- LEAF
  (1470, 'Lectures', 1, 0, 1), -- LEAF
  (1471, 'Leningrad Rock Club Scene', 0, 0, 0), -- LEAF
  (1472, 'Lento violento', 0, 0, 0), -- LEAF
  (1473, 'Levantine Arabic Music', 0, 2, 0), -- 2 children
  (1474, 'Levenslied', 0, 0, 0), -- LEAF
  (1475, 'Library Music', 0, 0, 0), -- LEAF
  (1476, 'Lied', 1, 0, 1), -- LEAF
  (1477, 'Liedermacher', 0, 0, 0), -- LEAF
  (1478, 'Light Music', 0, 0, 0), -- LEAF
  (1479, 'Lilat', 0, 0, 0), -- LEAF
  (1480, 'Liquid Drum and Bass', 3, 1, 3), -- 1 children
  (1481, 'Liquid Riddim', 0, 0, 0), -- LEAF
  (1482, 'Liscio', 0, 0, 0), -- LEAF
  (1483, 'Lisu Music', 0, 0, 0), -- LEAF
  (1484, 'Lithuanian Folk Music', 0, 1, 0), -- 1 children
  (1485, 'Little Band Scene', 0, 0, 0), -- LEAF
  (1486, 'Livetronica', 0, 0, 0), -- LEAF
  (1487, 'Livonian Folk Music', 0, 0, 0), -- LEAF
  (1488, 'Liwa', 0, 0, 0), -- LEAF
  (1489, 'Lo-Fi Hip Hop', 2, 0, 2), -- LEAF
  (1490, 'Lo-Fi House', 0, 0, 0), -- LEAF
  (1491, 'Loft Jazz', 0, 0, 0), -- LEAF
  (1492, 'Lokal musik', 0, 0, 0), -- LEAF
  (1493, 'Lolicore', 0, 0, 0), -- LEAF
  (1494, 'Loner Folk', 1, 0, 1), -- LEAF
  (1495, 'Los Angeles Counterculture', 0, 0, 0), -- LEAF
  (1496, 'Louisiana Music', 0, 8, 0), -- 8 children
  (1497, 'Louisville Sound', 0, 0, 0), -- LEAF
  (1498, 'Lounge', 6, 0, 6), -- LEAF
  (1499, 'Lovers Rock', 1, 0, 1), -- LEAF
  (1500, 'Lowend', 0, 0, 0), -- LEAF
  (1501, 'Lowercase', 0, 0, 0), -- LEAF
  (1502, 'Luk krung', 0, 1, 0), -- 1 children
  (1503, 'Luk thung', 0, 0, 0), -- LEAF
  (1504, 'Lullabies', 1, 1, 1), -- 1 children
  (1505, 'Lundu', 0, 0, 0), -- LEAF
  (1506, 'Luri Folk Music', 0, 0, 0), -- LEAF
  (1507, 'Luxembourgish Folk Music', 0, 0, 0), -- LEAF
  (1508, 'Ländler', 0, 0, 0), -- LEAF
  (1509, 'Macedonian Folk Music', 0, 1, 0), -- 1 children
  (1510, 'Machine Rock', 0, 0, 0), -- LEAF
  (1511, 'Madchester', 0, 0, 0), -- LEAF
  (1512, 'Maddahi', 0, 1, 0), -- 1 children
  (1513, 'Madrigal', 0, 0, 0), -- LEAF
  (1514, 'Mafioso Rap', 9, 0, 9), -- LEAF
  (1515, 'Maftirim', 0, 0, 0), -- LEAF
  (1516, 'Maghrebi Music', 0, 11, 0), -- 11 children
  (1517, 'Magyar nóta', 0, 0, 0), -- LEAF
  (1518, 'Mahori', 0, 0, 0), -- LEAF
  (1519, 'Mahraganat', 0, 0, 0), -- LEAF
  (1520, 'Maidcore', 0, 0, 0), -- LEAF
  (1521, 'Makina', 0, 0, 0), -- LEAF
  (1522, 'Makossa', 0, 0, 0), -- LEAF
  (1523, 'Malagasy Folk Music', 0, 0, 0), -- LEAF
  (1524, 'Malagasy Music', 0, 4, 0), -- 4 children
  (1525, 'Malagueña venezolana', 0, 0, 0), -- LEAF
  (1526, 'Malay Classical Music', 0, 1, 0), -- 1 children
  (1527, 'Malay Folk Music', 0, 0, 0), -- LEAF
  (1528, 'Malay Gamelan', 0, 0, 0), -- LEAF
  (1529, 'Malay Music', 0, 7, 0), -- 7 children
  (1530, 'Malayali Folk Music', 0, 1, 0), -- 1 children
  (1531, 'Malhun', 0, 0, 0), -- LEAF
  (1532, 'Mall Screamo', 2, 0, 2), -- LEAF
  (1533, 'Mallsoft', 0, 0, 0), -- LEAF
  (1534, 'Maloya', 0, 3, 0), -- 3 children
  (1535, 'Maloya électronique', 0, 0, 0), -- LEAF
  (1536, 'Maloya élektrik', 0, 0, 0), -- LEAF
  (1537, 'Mambo', 0, 0, 0), -- LEAF
  (1538, 'Mambo chileno', 0, 0, 0), -- LEAF
  (1539, 'Mambo urbano', 0, 0, 0), -- LEAF
  (1540, 'Manchu Music', 0, 0, 0), -- LEAF
  (1541, 'Mande Music', 0, 0, 0), -- LEAF
  (1542, 'Mandopop', 0, 0, 0), -- LEAF
  (1543, 'Manele', 0, 0, 0), -- LEAF
  (1544, 'Mangambeu', 0, 0, 0), -- LEAF
  (1545, 'Manguebeat', 0, 0, 0), -- LEAF
  (1546, 'Manila Sound', 0, 0, 0), -- LEAF
  (1547, 'Mantra', 0, 2, 0), -- 2 children
  (1548, 'Manx Folk Music', 0, 0, 0), -- LEAF
  (1549, 'Manyao', 0, 0, 0), -- LEAF
  (1550, 'Manzuma', 0, 0, 0), -- LEAF
  (1551, 'Mappila', 0, 0, 0), -- LEAF
  (1552, 'Mapuche Folk Music', 0, 0, 0), -- LEAF
  (1553, 'Maqāmic Music', 0, 12, 2), -- 12 children
  (1554, 'Marabi', 0, 2, 0), -- 2 children
  (1555, 'Maracatu', 0, 0, 0), -- LEAF
  (1556, 'Marathi Folk Music', 0, 1, 0), -- 1 children
  (1557, 'March', 0, 4, 1), -- 4 children
  (1558, 'Marching Band', 0, 7, 0), -- 7 children
  (1559, 'Marchinha', 0, 0, 0), -- LEAF
  (1560, 'Mari Folk Music', 0, 0, 0), -- LEAF
  (1561, 'Mariachi', 0, 0, 0), -- LEAF
  (1562, 'Marinera', 0, 0, 0), -- LEAF
  (1563, 'Marrabenta', 0, 0, 0), -- LEAF
  (1564, 'Martial Industrial', 3, 0, 3), -- LEAF
  (1565, 'Mashcore', 0, 0, 0), -- LEAF
  (1566, 'Mashup', 2, 0, 2), -- LEAF
  (1567, 'Maskandi', 0, 0, 0), -- LEAF
  (1568, 'Mass', 0, 1, 0), -- 1 children
  (1569, 'Mataali', 0, 0, 0), -- LEAF
  (1570, 'Math Pop', 10, 0, 10), -- LEAF
  (1571, 'Math Rock', 21, 1, 25), -- 1 children
  (1572, 'Mathcore', 28, 0, 28), -- LEAF
  (1573, 'Maxixe', 0, 0, 0), -- LEAF
  (1574, 'Maya Music', 0, 0, 0), -- LEAF
  (1575, 'Mazur', 0, 0, 0), -- LEAF
  (1576, 'Mazurka', 0, 0, 0), -- LEAF
  (1577, 'Mbalax', 0, 0, 0), -- LEAF
  (1578, 'Mbaqanga', 0, 0, 0), -- LEAF
  (1579, 'Mbenga-Mbuti Music', 0, 0, 0), -- LEAF
  (1580, 'Mbolé', 0, 0, 0), -- LEAF
  (1581, 'Mbube', 0, 0, 0), -- LEAF
  (1582, 'Mchiriku', 0, 0, 0), -- LEAF
  (1583, 'Mechanical Music', 0, 0, 0), -- LEAF
  (1584, 'Medieval Classical Music', 0, 14, 1), -- 14 children
  (1585, 'Medieval Lyric Poetry', 0, 0, 0), -- LEAF
  (1586, 'Mega funk', 0, 0, 0), -- LEAF
  (1587, 'Meiji shinkyoku', 0, 0, 0), -- LEAF
  (1588, 'Melanesian Music', 0, 6, 0), -- 6 children
  (1589, 'Melbourne Bounce', 0, 0, 0), -- LEAF
  (1590, 'Melodic Bass', 0, 0, 0), -- LEAF
  (1591, 'Melodic Black Metal', 8, 0, 8), -- LEAF
  (1592, 'Melodic Death Metal', 4, 1, 4), -- 1 children
  (1593, 'Melodic Dubstep', 0, 0, 0), -- LEAF
  (1594, 'Melodic Hardcore', 2, 0, 2), -- LEAF
  (1595, 'Melodic House', 0, 0, 0), -- LEAF
  (1596, 'Melodic Metalcore', 0, 0, 0), -- LEAF
  (1597, 'Melodic Techno', 0, 0, 0), -- LEAF
  (1598, 'Memphis Rap', 6, 2, 6), -- 2 children
  (1599, 'Mentai Rock', 0, 0, 0), -- LEAF
  (1600, 'Mento', 0, 0, 0), -- LEAF
  (1601, 'Merecumbé', 0, 0, 0), -- LEAF
  (1602, 'Merengue', 0, 5, 0), -- 5 children
  (1603, 'Merengue típico', 0, 0, 0), -- LEAF
  (1604, 'Merenhouse', 0, 0, 0), -- LEAF
  (1605, 'Merseybeat', 0, 0, 0), -- LEAF
  (1606, 'Mesoamerican Music', 0, 3, 0), -- 3 children
  (1607, 'Mesopotamian Music', 0, 0, 0), -- LEAF
  (1608, 'Metal', 0, 77, 250), -- 77 children
  (1609, 'Metalcore', 21, 5, 47), -- 5 children
  (1610, 'Mexican Folk Music', 0, 7, 0), -- 7 children
  (1611, 'Mexican Music', 0, 26, 0), -- 26 children
  (1612, 'Meyxana', 0, 0, 0), -- LEAF
  (1613, 'Miami Bass', 0, 4, 2), -- 4 children
  (1614, 'Microfunk', 0, 0, 0), -- LEAF
  (1615, 'Microhouse', 4, 0, 4), -- LEAF
  (1616, 'Micromontage', 2, 0, 2), -- LEAF
  (1617, 'Micronesian Music', 0, 1, 0), -- 1 children
  (1618, 'Microtonal Classical', 0, 0, 0), -- LEAF
  (1619, 'Mid-School Hip Hop', 1, 0, 1), -- LEAF
  (1620, 'MIDI Music', 3, 1, 3), -- 1 children
  (1621, 'Midtempo Bass', 0, 0, 0), -- LEAF
  (1622, 'Midwest Emo', 14, 0, 14), -- LEAF
  (1623, 'Midwest Hip Hop', 0, 0, 0), -- LEAF
  (1624, 'Miejski folk', 0, 0, 0), -- LEAF
  (1625, 'Military Cadence', 0, 0, 0), -- LEAF
  (1626, 'Milonga', 0, 0, 0), -- LEAF
  (1628, 'Min''yō', 1, 0, 1), -- LEAF
  (1629, 'Minangkabau Music', 0, 4, 0), -- 4 children
  (1630, 'Minatory', 0, 0, 0), -- LEAF
  (1631, 'Mincecore', 3, 0, 3), -- LEAF
  (1632, 'Minimal Drum and Bass', 0, 2, 0), -- 2 children
  (1633, 'Minimal Synth', 6, 0, 6), -- LEAF
  (1634, 'Minimal Techno', 4, 1, 5), -- 1 children
  (1635, 'Minimal Wave', 7, 1, 12), -- 1 children
  (1636, 'Minimalism', 7, 1, 7), -- 1 children
  (1637, 'Minneapolis Sound', 7, 0, 7), -- LEAF
  (1638, 'Minstrelsy', 0, 0, 0), -- LEAF
  (1639, 'Minyue', 0, 0, 0), -- LEAF
  (1640, 'Mittelalter-Metal', 0, 0, 0), -- LEAF
  (1641, 'Mittelalter-Rock', 0, 0, 0), -- LEAF
  (1642, 'Mobb Music', 0, 0, 0), -- LEAF
  (1643, 'Mod', 0, 1, 0), -- 1 children
  (1644, 'Mod Revival', 0, 0, 0), -- LEAF
  (1645, 'Moda de viola', 0, 0, 0), -- LEAF
  (1646, 'Modal Jazz', 4, 1, 4), -- 1 children
  (1647, 'Modern Classical', 9, 19, 30), -- 19 children
  (1648, 'Modern Creative', 2, 0, 2), -- LEAF
  (1649, 'Modern Laika', 0, 0, 0), -- LEAF
  (1650, 'Modinha', 0, 1, 0), -- 1 children
  (1651, 'Molam', 0, 1, 0), -- 1 children
  (1652, 'Molam sing', 0, 0, 0), -- LEAF
  (1653, 'Mongolian Music', 0, 6, 0), -- 6 children
  (1654, 'Mongolian Throat Singing', 0, 0, 0), -- LEAF
  (1655, 'Mono', 0, 0, 0), -- LEAF
  (1656, 'Monodrama', 0, 0, 0), -- LEAF
  (1657, 'Montenegrin Folk Music', 0, 0, 0), -- LEAF
  (1658, 'Mood kayō', 0, 0, 0), -- LEAF
  (1659, 'Moogsploitation', 0, 0, 0), -- LEAF
  (1660, 'Moombahcore', 0, 0, 0), -- LEAF
  (1661, 'Moombahton', 1, 0, 1), -- LEAF
  (1662, 'Moorish Music', 0, 0, 0), -- LEAF
  (1663, 'Moravian Folk Music', 0, 0, 0), -- LEAF
  (1664, 'Mordvin Folk Music', 0, 0, 0), -- LEAF
  (1665, 'Morenada', 0, 0, 0), -- LEAF
  (1666, 'Morna', 0, 0, 0), -- LEAF
  (1667, 'Moroccan Chaabi', 0, 0, 0), -- LEAF
  (1668, 'Morris Music', 0, 0, 0), -- LEAF
  (1669, 'Moscow School', 0, 0, 0), -- LEAF
  (1670, 'Mossi Music', 0, 0, 0), -- LEAF
  (1671, 'Motet', 0, 0, 0), -- LEAF
  (1672, 'Motown Sound', 0, 0, 0), -- LEAF
  (1673, 'Motswako', 0, 0, 0), -- LEAF
  (1674, 'Moutya', 0, 0, 0), -- LEAF
  (1675, 'Movida madrileña', 0, 0, 0), -- LEAF
  (1676, 'Movimiento Alterado', 0, 0, 0), -- LEAF
  (1677, 'Mozambique', 0, 0, 0), -- LEAF
  (1678, 'MPB', 1, 1, 2), -- 1 children
  (1679, 'Muak', 0, 0, 0), -- LEAF
  (1680, 'Mugithi', 0, 0, 0), -- LEAF
  (1681, 'Mulatós', 0, 0, 0), -- LEAF
  (1682, 'Muliza', 0, 0, 0), -- LEAF
  (1683, 'Murga', 0, 1, 0), -- 1 children
  (1684, 'Murga uruguaya', 0, 0, 0), -- LEAF
  (1685, 'Musette', 0, 1, 0), -- 1 children
  (1686, 'Music Hall', 0, 0, 0), -- LEAF
  (1687, 'Musical Comedy', 0, 4, 3), -- 4 children
  (1688, 'Musical Parody', 1, 0, 1), -- LEAF
  (1689, 'Musical Theatre and Entertainment', 0, 21, 3), -- 21 children
  (1690, 'Musika popullore', 0, 0, 0), -- LEAF
  (1691, 'Musique concrète', 22, 0, 22), -- LEAF
  (1692, 'Musique concrète instrumentale', 1, 0, 1), -- LEAF
  (1693, 'Mutant Disco', 7, 0, 7), -- LEAF
  (1694, 'Muzică de mahala', 0, 0, 0), -- LEAF
  (1695, 'Muzică lăutărească', 0, 0, 0), -- LEAF
  (1696, 'Muzika mizrahit', 0, 1, 0), -- 1 children
  (1697, 'Muzika yehudit mekorit', 0, 0, 0), -- LEAF
  (1698, 'Muzikat dika''on', 0, 0, 0), -- LEAF
  (1699, 'Muziki wa dansi', 0, 0, 0), -- LEAF
  (1700, 'Mélodie', 0, 0, 0), -- LEAF
  (1701, 'Méringue', 0, 0, 0), -- LEAF
  (1702, 'Métis Fiddling', 0, 0, 0), -- LEAF
  (1703, 'Métis Music', 0, 1, 0), -- 1 children
  (1704, 'Música cebolla', 0, 0, 0), -- LEAF
  (1705, 'Música criolla peruana', 0, 6, 0), -- 6 children
  (1706, 'Música de intervenção', 0, 0, 0), -- LEAF
  (1707, 'Música festera', 0, 0, 0), -- LEAF
  (1708, 'Música gaúcha', 0, 1, 0), -- 1 children
  (1709, 'Música llanera', 0, 0, 0), -- LEAF
  (1710, 'Música típica chilena', 0, 1, 0), -- 1 children
  (1711, 'Māori Music', 0, 0, 0), -- LEAF
  (1712, 'Młoda Polska', 0, 0, 0), -- LEAF
  (1713, 'Mūsīqā lubnāniyya', 0, 0, 0), -- LEAF
  (1714, 'Nagauta', 0, 0, 0), -- LEAF
  (1715, 'Nagoya kei', 0, 0, 0), -- LEAF
  (1716, 'Nahua Music', 0, 0, 0), -- LEAF
  (1717, 'Nanyin', 0, 0, 0), -- LEAF
  (1718, 'Nardcore', 0, 0, 0), -- LEAF
  (1719, 'Narodno zabavna glasba', 0, 0, 0), -- LEAF
  (1720, 'Nasheed', 0, 0, 0), -- LEAF
  (1721, 'Nashville Sound', 0, 1, 0), -- 1 children
  (1722, 'Native American New Age', 0, 0, 0), -- LEAF
  (1723, 'Nature Recordings', 10, 5, 10), -- 5 children
  (1724, 'Naturjodel', 0, 0, 0), -- LEAF
  (1725, 'Navajo Music', 0, 0, 0), -- LEAF
  (1726, 'Naxi Music', 0, 2, 0), -- 2 children
  (1727, 'Nederbeat', 0, 0, 0), -- LEAF
  (1728, 'Nederpop', 0, 1, 0), -- 1 children
  (1729, 'Neo Kyma', 0, 0, 0), -- LEAF
  (1730, 'Neo Rave', 0, 0, 0), -- LEAF
  (1731, 'Neo-Acoustic', 0, 0, 0), -- LEAF
  (1732, 'Neo-Bop', 0, 0, 0), -- LEAF
  (1733, 'Neo-Canterbury', 0, 0, 0), -- LEAF
  (1734, 'Neo-City Pop', 0, 0, 0), -- LEAF
  (1735, 'Neo-Grime', 0, 0, 0), -- LEAF
  (1736, 'Neo-Medieval Folk', 1, 1, 1), -- 1 children
  (1737, 'Neo-Pagan Folk', 0, 0, 0), -- LEAF
  (1738, 'Neo-Prog', 0, 0, 0), -- LEAF
  (1739, 'Neo-Psychedelia', 86, 5, 129), -- 5 children
  (1740, 'Neo-Soul', 44, 0, 44), -- LEAF
  (1741, 'Neo-Traditionalist Country', 0, 0, 0), -- LEAF
  (1742, 'Neoclassical Darkwave', 13, 0, 13), -- LEAF
  (1743, 'Neoclassical Metal', 0, 0, 0), -- LEAF
  (1744, 'Neoclassical New Age', 6, 0, 6), -- LEAF
  (1745, 'Neoclassicism', 0, 0, 0), -- LEAF
  (1746, 'Neocrust', 1, 0, 1), -- LEAF
  (1747, 'Neofolk', 7, 1, 14), -- 1 children
  (1748, 'Neofolklore', 0, 0, 0), -- LEAF
  (1749, 'Neon Pop Punk', 0, 0, 0), -- LEAF
  (1750, 'Neoperreo', 2, 0, 2), -- LEAF
  (1751, 'Neoromanticism', 0, 0, 0), -- LEAF
  (1752, 'Nepali lok geet', 0, 0, 0), -- LEAF
  (1753, 'Nerdcore Hip Hop', 1, 0, 1), -- LEAF
  (1754, 'Nerdcore Techno', 0, 0, 0), -- LEAF
  (1755, 'Nervous Music', 0, 0, 0), -- LEAF
  (1756, 'Neue Deutsche Härte', 0, 0, 0), -- LEAF
  (1757, 'Neue Deutsche Todeskunst', 0, 0, 0), -- LEAF
  (1758, 'Neue Deutsche Welle', 0, 0, 0), -- LEAF
  (1759, 'Neue Volksmusik', 0, 0, 0), -- LEAF
  (1760, 'Neurofunk', 1, 0, 1), -- LEAF
  (1761, 'Neurohop', 0, 0, 0), -- LEAF
  (1762, 'New Age', 13, 6, 19), -- 6 children
  (1763, 'New Age Kirtan', 1, 0, 1), -- LEAF
  (1764, 'New Beat', 0, 1, 0), -- 1 children
  (1765, 'New Brunswick Basement Scene', 0, 0, 0), -- LEAF
  (1766, 'New Complexity', 0, 0, 0), -- LEAF
  (1767, 'New Direction', 0, 0, 0), -- LEAF
  (1768, 'New German School', 0, 0, 0), -- LEAF
  (1769, 'New Jack Swing', 4, 0, 4), -- LEAF
  (1770, 'New Jazz', 0, 0, 0), -- LEAF
  (1771, 'New London Jazz', 0, 0, 0), -- LEAF
  (1772, 'New Mexico Music', 0, 0, 0), -- LEAF
  (1773, 'New Music', 1, 0, 1), -- LEAF
  (1774, 'New Orleans Blues', 0, 0, 0), -- LEAF
  (1775, 'New Orleans Brass Band', 0, 0, 0), -- LEAF
  (1776, 'New Orleans R&B', 0, 0, 0), -- LEAF
  (1777, 'New Partisans', 0, 0, 0), -- LEAF
  (1778, 'New Pop', 0, 0, 0), -- LEAF
  (1779, 'New Primitivism', 0, 0, 0), -- LEAF
  (1780, 'New Rave', 10, 0, 10), -- LEAF
  (1781, 'New Romantic', 0, 0, 0), -- LEAF
  (1782, 'New Tone', 0, 0, 0), -- LEAF
  (1783, 'New Wave', 18, 3, 18), -- 3 children
  (1784, 'New Wave of New Wave', 0, 0, 0), -- LEAF
  (1785, 'New Way of Danish Fuck You', 0, 0, 0), -- LEAF
  (1786, 'New Weird America', 4, 0, 4), -- LEAF
  (1787, 'New Weird Finland', 0, 0, 0), -- LEAF
  (1788, 'New York Drill', 0, 2, 1), -- 2 children
  (1789, 'New York Hardcore', 0, 0, 0), -- LEAF
  (1790, 'New York School', 0, 0, 0), -- LEAF
  (1791, 'Newa Music', 0, 0, 0), -- LEAF
  (1792, 'Newfoundland Folk Music', 0, 0, 0), -- LEAF
  (1793, 'Ngoma', 0, 1, 0), -- 1 children
  (1794, 'Nguni Folk Music', 0, 0, 0), -- LEAF
  (1795, 'Ngâm thơ', 0, 0, 0), -- LEAF
  (1796, 'Nhạc tiền chiến', 0, 0, 0), -- LEAF
  (1797, 'Nhạc vàng', 0, 0, 0), -- LEAF
  (1798, 'Nhạc đỏ', 0, 0, 0), -- LEAF
  (1799, 'Nightcore', 2, 0, 2), -- LEAF
  (1800, 'Nigun', 0, 0, 0), -- LEAF
  (1801, 'Nintendocore', 1, 0, 1), -- LEAF
  (1802, 'Nitzhonot', 0, 0, 0), -- LEAF
  (1803, 'Nivkh Music', 0, 0, 0), -- LEAF
  (1804, 'No Melody', 0, 0, 0), -- LEAF
  (1805, 'No Wave', 10, 0, 10), -- LEAF
  (1806, 'Nocturne', 0, 0, 0), -- LEAF
  (1807, 'Noh', 0, 0, 0), -- LEAF
  (1808, 'Noiadance', 0, 0, 0), -- LEAF
  (1809, 'Noise', 51, 8, 115), -- 8 children
  (1810, 'Noise Pop', 33, 0, 33), -- LEAF
  (1811, 'Noise Rock', 82, 2, 83), -- 2 children
  (1812, 'Noisecore', 8, 0, 8), -- LEAF
  (1813, 'Noisegrind', 8, 0, 8), -- LEAF
  (1814, 'NOLA Sludge', 0, 0, 0), -- LEAF
  (1815, 'Nordic Folk Music', 0, 10, 1), -- 10 children
  (1816, 'Nordic Folk Rock', 0, 0, 0), -- LEAF
  (1817, 'Nordic Music', 0, 22, 1), -- 22 children
  (1818, 'Nordic Old Time Dance Music', 0, 2, 0), -- 2 children
  (1819, 'Nortec', 0, 0, 0), -- LEAF
  (1820, 'Norteño', 0, 5, 0), -- 5 children
  (1821, 'North African Music', 0, 31, 0), -- 31 children
  (1822, 'North Asian Music', 0, 19, 1), -- 19 children
  (1823, 'Northeastern African Music', 0, 20, 0), -- 20 children
  (1824, 'Northeastern Brazilian Music', 1, 36, 1), -- 36 children
  (1825, 'Northern American Music', 0, 124, 20), -- 124 children
  (1826, 'Northern Brazilian Music', 0, 2, 0), -- 2 children
  (1827, 'Northern Gothic', 0, 0, 0), -- LEAF
  (1828, 'Northern Soul', 0, 0, 0), -- LEAF
  (1829, 'Northumbrian Folk Music', 0, 0, 0), -- LEAF
  (1830, 'Norwegian Folk Music', 0, 0, 0), -- LEAF
  (1831, 'Nouveau zydeco', 0, 0, 0), -- LEAF
  (1832, 'Nouvelle chanson française', 0, 0, 0), -- LEAF
  (1833, 'Nova cançó', 0, 0, 0), -- LEAF
  (1834, 'Nova srpska scena', 0, 0, 0), -- LEAF
  (1835, 'Nova vanguarda paulistana', 0, 0, 0), -- LEAF
  (1836, 'Novaya scena', 0, 0, 0), -- LEAF
  (1837, 'Novelty', 1, 0, 1), -- LEAF
  (1838, 'Novelty Piano', 0, 0, 0), -- LEAF
  (1839, 'Novo Dub', 0, 0, 0), -- LEAF
  (1840, 'NRG', 0, 0, 0), -- LEAF
  (1841, 'Nu Jazz', 12, 0, 12), -- LEAF
  (1842, 'Nu Metal', 9, 0, 9), -- LEAF
  (1843, 'Nu Skool Breaks', 0, 0, 0), -- LEAF
  (1844, 'Nu Style Gabber', 0, 0, 0), -- LEAF
  (1845, 'Nu-Disco', 1, 0, 1), -- LEAF
  (1846, 'Nuban', 0, 0, 0), -- LEAF
  (1847, 'Nubian Music', 0, 0, 0), -- LEAF
  (1848, 'Nuer Music', 0, 0, 0), -- LEAF
  (1849, 'Nueva canción', 0, 5, 0), -- 5 children
  (1850, 'Nueva canción chilena', 0, 0, 0), -- LEAF
  (1851, 'Nueva canción española', 0, 0, 0), -- LEAF
  (1852, 'Nueva canción latinoamericana', 0, 3, 0), -- 3 children
  (1853, 'Nueva cumbia chilena', 0, 0, 0), -- LEAF
  (1854, 'Nueva escena chilena', 0, 0, 0), -- LEAF
  (1855, 'Nueva ola', 0, 0, 0), -- LEAF
  (1856, 'Nueva trova', 0, 0, 0), -- LEAF
  (1857, 'Nuevo Cancionero', 0, 0, 0), -- LEAF
  (1858, 'Nursery Rhymes', 0, 0, 0), -- LEAF
  (1859, 'Nustyle', 0, 0, 0), -- LEAF
  (1860, 'NWOBHM', 0, 0, 0), -- LEAF
  (1861, 'Nyahbinghi', 1, 0, 1), -- LEAF
  (1862, 'Nòva cançon', 0, 0, 0), -- LEAF
  (1863, 'O''odham Music', 0, 1, 0), -- 1 children
  (1864, 'Ob-Ugric Folk Music', 0, 0, 0), -- LEAF
  (1865, 'Oberek', 0, 0, 0), -- LEAF
  (1866, 'Occitan Folk Music', 0, 3, 0), -- 3 children
  (1867, 'Occult Rock', 0, 0, 0), -- LEAF
  (1868, 'Oceanian Music', 0, 24, 1), -- 24 children
  (1869, 'Odia Folk Music', 0, 0, 0), -- LEAF
  (1870, 'Odissi Classical Music', 0, 0, 0), -- LEAF
  (1871, 'Ogene Music', 0, 0, 0), -- LEAF
  (1872, 'Oi!', 0, 0, 0), -- LEAF
  (1873, 'Okinawan Music', 0, 0, 0), -- LEAF
  (1874, 'Old Roman Chant', 0, 0, 0), -- LEAF
  (1875, 'Old-Time', 0, 0, 0), -- LEAF
  (1876, 'Omutibo', 0, 0, 0), -- LEAF
  (1877, 'Onda nueva', 0, 0, 0), -- LEAF
  (1878, 'Ondō', 0, 0, 0), -- LEAF
  (1879, 'Onkyo', 0, 0, 0), -- LEAF
  (1880, 'Opera', 2, 19, 3), -- 19 children
  (1881, 'Opera buffa', 0, 0, 0), -- LEAF
  (1882, 'Opera semiseria', 1, 0, 1), -- LEAF
  (1883, 'Opera seria', 0, 0, 0), -- LEAF
  (1884, 'Operetta', 0, 1, 0), -- 1 children
  (1885, 'OPM', 0, 0, 0), -- LEAF
  (1886, 'Opéra-ballet', 0, 0, 0), -- LEAF
  (1887, 'Opéra-comique', 0, 0, 0), -- LEAF
  (1888, 'Oratorio', 0, 0, 0), -- LEAF
  (1889, 'Orchestral Music', 2, 3, 2), -- 3 children
  (1890, 'Orchestral Song', 0, 0, 0), -- LEAF
  (1891, 'Organic House', 0, 0, 0), -- LEAF
  (1892, 'Ori deck', 0, 0, 0), -- LEAF
  (1893, 'Oriental Ballad', 0, 0, 0), -- LEAF
  (1894, 'Oriental Jewish Music', 0, 2, 0), -- 2 children
  (1895, 'Orkes gambus', 0, 0, 0), -- LEAF
  (1896, 'Oromo Music', 0, 0, 0), -- LEAF
  (1897, 'Orthodox Pop', 0, 0, 0), -- LEAF
  (1898, 'Ossetian Folk Music', 0, 0, 0), -- LEAF
  (1899, 'otoMAD', 0, 0, 0), -- LEAF
  (1900, 'Ottoman Military Music', 0, 0, 0), -- LEAF
  (1901, 'Outlaw Country', 0, 0, 0), -- LEAF
  (1902, 'Outrun', 0, 0, 0), -- LEAF
  (1903, 'Outsider House', 0, 1, 0), -- 1 children
  (1904, 'Overture', 0, 0, 0), -- LEAF
  (1905, 'P-Funk', 4, 0, 4), -- LEAF
  (1906, 'P-Pop', 0, 0, 0), -- LEAF
  (1907, 'Pachanga', 0, 0, 0), -- LEAF
  (1908, 'Pacific Reggae', 0, 1, 0), -- 1 children
  (1909, 'Pagan Black Metal', 1, 0, 1), -- LEAF
  (1910, 'Paghjella', 0, 0, 0), -- LEAF
  (1911, 'Pagode', 0, 3, 0), -- 3 children
  (1912, 'Pagode romântico', 0, 0, 0), -- LEAF
  (1913, 'Pagodão', 0, 1, 0), -- 1 children
  (1914, 'Paisley Underground', 0, 0, 0), -- LEAF
  (1915, 'Pakacaping Music', 0, 0, 0), -- LEAF
  (1916, 'Palingsound', 0, 0, 0), -- LEAF
  (1917, 'Palm Desert Scene', 0, 0, 0), -- LEAF
  (1918, 'Palm Wine Music', 0, 0, 0), -- LEAF
  (1919, 'Palo de mayo', 0, 0, 0), -- LEAF
  (1920, 'Pamiri Music', 0, 1, 0), -- 1 children
  (1921, 'Pandilla', 0, 0, 0), -- LEAF
  (1922, 'Pansori', 0, 0, 0), -- LEAF
  (1923, 'Pansy Craze', 0, 0, 0), -- LEAF
  (1924, 'Papuan Folk Music', 0, 0, 0), -- LEAF
  (1925, 'Paramaribop', 0, 0, 0), -- LEAF
  (1926, 'Parang', 0, 0, 0), -- LEAF
  (1927, 'Parlour Music', 0, 0, 0), -- LEAF
  (1928, 'Partido alto', 0, 0, 0), -- LEAF
  (1929, 'Pashto Folk Music', 0, 0, 0), -- LEAF
  (1930, 'Pasillo', 0, 0, 0), -- LEAF
  (1931, 'Pasodoble', 0, 0, 0), -- LEAF
  (1932, 'Passion', 0, 0, 0), -- LEAF
  (1933, 'Payada', 0, 0, 0), -- LEAF
  (1934, 'Peak Time Techno', 0, 0, 0), -- LEAF
  (1935, 'Peking Opera', 0, 2, 0), -- 2 children
  (1936, 'Pennsylvania Dutch Folk Music', 0, 0, 0), -- LEAF
  (1937, 'Pep Band', 0, 0, 0), -- LEAF
  (1938, 'Persian Classical Music', 0, 0, 0), -- LEAF
  (1939, 'Persian Folk Music', 0, 0, 0), -- LEAF
  (1940, 'Persian Music', 0, 6, 0), -- 6 children
  (1941, 'Persian Pop', 0, 0, 0), -- LEAF
  (1942, 'Peruvian Music', 0, 17, 0), -- 17 children
  (1943, 'Pessoal do Ceará', 0, 0, 0), -- LEAF
  (1944, 'Philippine Music', 0, 8, 0), -- 8 children
  (1945, 'Philippine Rondalla', 0, 0, 0), -- LEAF
  (1946, 'Philly Club', 1, 0, 1), -- LEAF
  (1947, 'Philly Club Rap', 0, 0, 0), -- LEAF
  (1948, 'Philly Drill', 0, 0, 0), -- LEAF
  (1949, 'Philly Soul', 4, 0, 4), -- LEAF
  (1950, 'Phleng phuea chiwit', 0, 0, 0), -- LEAF
  (1951, 'Phonk', 0, 0, 0), -- LEAF
  (1952, 'Phonk House', 0, 0, 0), -- LEAF
  (1953, 'Piano Blues', 3, 0, 3), -- LEAF
  (1954, 'Piano Rock', 7, 0, 7), -- LEAF
  (1955, 'Picopop', 0, 0, 0), -- LEAF
  (1956, 'Piedmont Blues', 0, 0, 0), -- LEAF
  (1957, 'Pigfuck', 11, 0, 11), -- LEAF
  (1958, 'Pilón', 0, 0, 0), -- LEAF
  (1959, 'Pimba', 0, 0, 0), -- LEAF
  (1960, 'Pinoy Folk Rock', 0, 0, 0), -- LEAF
  (1961, 'Pinpeat', 0, 0, 0), -- LEAF
  (1962, 'Piosenka aktorska', 0, 0, 0), -- LEAF
  (1963, 'Pipe Band', 0, 0, 0), -- LEAF
  (1964, 'Piphat', 0, 0, 0), -- LEAF
  (1965, 'Pirekua', 0, 0, 0), -- LEAF
  (1966, 'Piseiro', 0, 0, 0), -- LEAF
  (1967, 'Piyyut', 0, 2, 0), -- 2 children
  (1968, 'Pizzica', 0, 0, 0), -- LEAF
  (1969, 'Plainsong', 0, 8, 1), -- 8 children
  (1970, 'Plena', 0, 0, 0), -- LEAF
  (1971, 'Plugg', 4, 5, 6), -- 5 children
  (1972, 'PluggnB', 1, 1, 1), -- 1 children
  (1973, 'Plunderphonics', 16, 0, 16), -- LEAF
  (1974, 'Poetry', 7, 7, 12), -- 7 children
  (1975, 'Poezja śpiewana', 0, 0, 0), -- LEAF
  (1976, 'Polifonia occitana', 0, 0, 0), -- LEAF
  (1977, 'Polish Folk Music', 1, 9, 1), -- 9 children
  (1978, 'Polish Goral Music', 0, 0, 0), -- LEAF
  (1979, 'Polish Music', 0, 19, 1), -- 19 children
  (1980, 'Political Hip Hop', 26, 0, 26), -- LEAF
  (1981, 'Polka', 0, 3, 0), -- 3 children
  (1982, 'Polka paraguaya', 0, 0, 0), -- LEAF
  (1983, 'Polka peruana', 0, 0, 0), -- LEAF
  (1984, 'Polonaise', 0, 0, 0), -- LEAF
  (1985, 'Polska', 0, 1, 0), -- 1 children
  (1986, 'Polynesian Music', 0, 11, 0), -- 11 children
  (1987, 'Polyphonic Chant', 0, 16, 0), -- 16 children
  (1988, 'Pon-chak disco', 0, 0, 0), -- LEAF
  (1989, 'Ponto de umbanda', 0, 0, 0), -- LEAF
  (1990, 'Pop', 0, 173, 189), -- 173 children
  (1991, 'Pop Batak', 0, 0, 0), -- LEAF
  (1992, 'Pop Ghazal', 0, 0, 0), -- LEAF
  (1993, 'Pop Kreatif', 0, 0, 0), -- LEAF
  (1994, 'Pop Minang', 0, 1, 0), -- 1 children
  (1995, 'Pop Punk', 12, 3, 12), -- 3 children
  (1996, 'Pop Rap', 28, 3, 30), -- 3 children
  (1997, 'Pop Raï', 0, 0, 0), -- LEAF
  (1998, 'Pop Reggae', 1, 0, 1), -- LEAF
  (1999, 'Pop Rock', 12, 25, 43), -- 25 children
  (2000, 'Pop Soul', 5, 1, 5), -- 1 children
  (2001, 'Pop Sunda', 0, 0, 0), -- LEAF
  (2002, 'Pop Yeh-Yeh', 0, 0, 0), -- LEAF
  (2003, 'Pops Orchestra', 0, 0, 0), -- LEAF
  (2004, 'Porn Groove', 0, 0, 0), -- LEAF
  (2005, 'Pornogrind', 1, 0, 1), -- LEAF
  (2006, 'Porro', 0, 0, 0), -- LEAF
  (2007, 'Portuguese Folk Music', 0, 7, 0), -- 7 children
  (2008, 'Portuguese Music', 0, 10, 0), -- 10 children
  (2009, 'Positive Punk', 0, 0, 0), -- LEAF
  (2011, 'Post-Black Metal', 1, 0, 1), -- LEAF
  (2012, 'Post-Bop', 7, 0, 7), -- LEAF
  (2013, 'Post-Britpop', 2, 0, 2), -- LEAF
  (2014, 'Post-Dubstep', 3, 0, 3), -- LEAF
  (2015, 'Post-Grunge', 0, 0, 0), -- LEAF
  (2016, 'Post-Hardcore', 53, 5, 62), -- 5 children
  (2017, 'Post-Industrial', 39, 23, 177), -- 23 children
  (2018, 'Post-Metal', 24, 3, 41), -- 3 children
  (2019, 'Post-Minimalism', 13, 1, 16), -- 1 children
  (2020, 'Post-Punk', 63, 7, 85), -- 7 children
  (2021, 'Post-Punk Revival', 6, 1, 11), -- 1 children
  (2022, 'Post-Rock', 82, 0, 82), -- LEAF
  (2023, 'Power Electronics', 26, 1, 37), -- 1 children
  (2024, 'Power Metal', 0, 0, 0), -- LEAF
  (2025, 'Power Noise', 17, 0, 17), -- LEAF
  (2026, 'Power Pop', 10, 0, 10), -- LEAF
  (2027, 'Power Soca', 0, 0, 0), -- LEAF
  (2028, 'Powerstomp', 0, 0, 0), -- LEAF
  (2029, 'Powerviolence', 11, 0, 11), -- LEAF
  (2030, 'Powwow Music', 0, 0, 0), -- LEAF
  (2031, 'Praise & Worship', 0, 1, 0), -- 1 children
  (2032, 'Praise Break', 0, 0, 0), -- LEAF
  (2033, 'Prank Call', 0, 0, 0), -- LEAF
  (2034, 'Prank Calls', 1, 0, 1), -- LEAF
  (2035, 'Prehistoric Music', 0, 0, 0), -- LEAF
  (2036, 'Prelude', 0, 0, 0), -- LEAF
  (2037, 'Process Music', 0, 0, 0), -- LEAF
  (2038, 'Progg', 0, 0, 0), -- LEAF
  (2039, 'Progressive Big Band', 0, 0, 0), -- LEAF
  (2040, 'Progressive Bluegrass', 0, 1, 0), -- 1 children
  (2041, 'Progressive Breaks', 1, 0, 1), -- LEAF
  (2042, 'Progressive Country', 0, 1, 0), -- 1 children
  (2043, 'Progressive Electronic', 22, 1, 23), -- 1 children
  (2044, 'Progressive Folk', 8, 0, 8), -- LEAF
  (2045, 'Progressive House', 5, 1, 5), -- 1 children
  (2046, 'Progressive Metal', 25, 0, 25), -- LEAF
  (2047, 'Progressive Pop', 29, 0, 29), -- LEAF
  (2048, 'Progressive Psytrance', 1, 1, 1), -- 1 children
  (2049, 'Progressive Rock', 26, 7, 62), -- 7 children
  (2050, 'Progressive Soul', 23, 0, 23), -- LEAF
  (2051, 'Progressive Trance', 0, 0, 0), -- LEAF
  (2052, 'Proto-Punk', 1, 0, 1), -- LEAF
  (2053, 'Psichedelia occulta italiana', 0, 0, 0), -- LEAF
  (2054, 'Psybient', 4, 0, 4), -- LEAF
  (2055, 'Psybreaks', 2, 0, 2), -- LEAF
  (2056, 'Psychedelia', 2, 28, 208), -- 28 children
  (2057, 'Psychedelic Folk', 18, 4, 24), -- 4 children
  (2058, 'Psychedelic Pop', 17, 0, 17), -- LEAF
  (2059, 'Psychedelic Rock', 47, 10, 62), -- 10 children
  (2060, 'Psychedelic Soul', 24, 0, 24), -- LEAF
  (2061, 'Psychobilly', 1, 1, 1), -- 1 children
  (2062, 'Psychsploitation', 0, 1, 0), -- 1 children
  (2063, 'Psycore', 1, 0, 1), -- LEAF
  (2064, 'Psystyle', 0, 0, 0), -- LEAF
  (2065, 'Psytrance', 2, 10, 4), -- 10 children
  (2066, 'Pub Rock', 0, 0, 0), -- LEAF
  (2067, 'Pueblo Music', 0, 0, 0), -- LEAF
  (2068, 'Pungmul', 0, 0, 0), -- LEAF
  (2069, 'Punjabi Folk Music', 0, 0, 0), -- LEAF
  (2070, 'Punk', 1, 84, 283), -- 84 children
  (2071, 'Punk Blues', 9, 0, 9), -- LEAF
  (2072, 'Punk Poetry', 0, 0, 0), -- LEAF
  (2073, 'Punk Rock', 3, 38, 68), -- 38 children
  (2074, 'Punta', 0, 0, 0), -- LEAF
  (2075, 'Purple Sound', 0, 0, 0), -- LEAF
  (2076, 'Purísima', 0, 0, 0), -- LEAF
  (2077, 'Puxa', 0, 0, 0), -- LEAF
  (2078, 'Pásztordal', 0, 0, 0), -- LEAF
  (2079, 'Pécs Underground Scene', 0, 0, 0), -- LEAF
  (2080, 'Pìobaireachd', 0, 0, 0), -- LEAF
  (2081, 'Q-Pop', 0, 0, 0), -- LEAF
  (2082, 'Qaraami', 0, 0, 0), -- LEAF
  (2083, 'Qasidah modern', 0, 0, 0), -- LEAF
  (2084, 'Qawwali', 1, 0, 1), -- LEAF
  (2085, 'Quan họ', 0, 0, 0), -- LEAF
  (2086, 'Queercore', 0, 0, 0), -- LEAF
  (2087, 'Quyi', 0, 0, 0), -- LEAF
  (2088, 'R&B', 0, 44, 134), -- 44 children
  (2089, 'Rabbit Song', 0, 0, 0), -- LEAF
  (2090, 'Rabiz', 0, 0, 0), -- LEAF
  (2091, 'RABM', 1, 0, 1), -- LEAF
  (2092, 'Rabòday', 0, 0, 0), -- LEAF
  (2093, 'Radio Broadcast Recordings', 4, 0, 4), -- LEAF
  (2094, 'Radio Drama', 2, 0, 2), -- LEAF
  (2095, 'Raga Rock', 3, 0, 3), -- LEAF
  (2096, 'Rage', 7, 0, 7), -- LEAF
  (2097, 'Ragga', 0, 0, 0), -- LEAF
  (2098, 'Ragga Jungle', 0, 0, 0), -- LEAF
  (2099, 'Raggacore', 0, 0, 0), -- LEAF
  (2100, 'Raggatek', 0, 0, 0), -- LEAF
  (2101, 'Ragtime', 1, 6, 1), -- 6 children
  (2102, 'Ragtime Song', 0, 0, 0), -- LEAF
  (2103, 'Rain Sounds', 0, 0, 0), -- LEAF
  (2104, 'Rajasthani Folk Music', 0, 0, 0), -- LEAF
  (2105, 'Ranchera', 0, 0, 0), -- LEAF
  (2106, 'Rap Metal', 2, 0, 2), -- LEAF
  (2107, 'Rap Rock', 3, 1, 5), -- 1 children
  (2108, 'Rapai dabõih', 0, 0, 0), -- LEAF
  (2109, 'Rapso', 0, 0, 0), -- LEAF
  (2110, 'Raqs baladi', 0, 0, 0), -- LEAF
  (2111, 'Rara', 0, 0, 0), -- LEAF
  (2112, 'Rare Phonk', 0, 0, 0), -- LEAF
  (2113, 'Rasin', 0, 0, 0), -- LEAF
  (2114, 'Rasqueado', 0, 0, 0), -- LEAF
  (2115, 'Rasteirinha', 0, 0, 0), -- LEAF
  (2116, 'Ratchet', 0, 0, 0), -- LEAF
  (2117, 'Rautalanka', 0, 0, 0), -- LEAF
  (2118, 'Rawphoric', 0, 0, 0), -- LEAF
  (2119, 'Rawstyle', 0, 2, 0), -- 2 children
  (2120, 'Raï', 0, 2, 0), -- 2 children
  (2121, 'Red Dirt', 0, 0, 0), -- LEAF
  (2122, 'Red Disco', 0, 0, 0), -- LEAF
  (2123, 'Reductionism', 5, 3, 5), -- 3 children
  (2124, 'Regalia', 0, 0, 0), -- LEAF
  (2125, 'Reggae', 1, 11, 12), -- 11 children
  (2126, 'Reggae / Ska / Dancehall', 0, 30, 21), -- 30 children
  (2127, 'Reggae Rock', 0, 0, 0), -- LEAF
  (2128, 'Reggaetón', 0, 8, 2), -- 8 children
  (2129, 'Regional Music', 0, 1537, 81), -- 1537 children
  (2130, 'Rembetika', 0, 0, 0), -- LEAF
  (2131, 'Renaissance Music', 0, 3, 0), -- 3 children
  (2132, 'Reparto', 0, 0, 0), -- LEAF
  (2133, 'Repente', 0, 0, 0), -- LEAF
  (2134, 'Requiem', 0, 0, 0), -- LEAF
  (2135, 'Revolution Summer', 0, 0, 0), -- LEAF
  (2136, 'Revolutionary Opera', 0, 0, 0), -- LEAF
  (2137, 'Revue', 1, 0, 1), -- LEAF
  (2138, 'Rhumba', 0, 0, 0), -- LEAF
  (2139, 'Rhythm & Blues', 4, 5, 6), -- 5 children
  (2140, 'Ricercar', 0, 0, 0), -- LEAF
  (2141, 'Riddim', 1, 2, 3), -- 2 children
  (2142, 'Rigsar', 0, 0, 0), -- LEAF
  (2143, 'Ring Shout', 0, 0, 0), -- LEAF
  (2144, 'Rioplatense Music', 0, 10, 0), -- 10 children
  (2145, 'Riot Grrrl', 0, 0, 0), -- LEAF
  (2146, 'Ripsaw', 0, 0, 0), -- LEAF
  (2147, 'Ritmada', 0, 0, 0), -- LEAF
  (2148, 'Ritual Ambient', 8, 0, 8), -- LEAF
  (2149, 'Rizitika', 0, 0, 0), -- LEAF
  (2150, 'RKT', 0, 0, 0), -- LEAF
  (2151, 'Road Rap', 0, 0, 0), -- LEAF
  (2152, 'Rock', 0, 283, 587), -- 283 children
  (2153, 'Rock & Roll', 1, 5, 2), -- 5 children
  (2154, 'Rock Against Racism', 0, 0, 0), -- LEAF
  (2155, 'Rock andaluz', 0, 0, 0), -- LEAF
  (2156, 'Rock andino', 0, 0, 0), -- LEAF
  (2157, 'Rock barrial', 0, 0, 0), -- LEAF
  (2158, 'Rock in Opposition', 2, 0, 2), -- LEAF
  (2159, 'Rock Kapak', 0, 0, 0), -- LEAF
  (2160, 'Rock Musical', 0, 0, 0), -- LEAF
  (2161, 'Rock Opera', 2, 0, 2), -- LEAF
  (2162, 'Rock radical vasco', 0, 0, 0), -- LEAF
  (2163, 'Rock rural', 0, 0, 0), -- LEAF
  (2164, 'Rock subterráneo', 0, 0, 0), -- LEAF
  (2165, 'Rock sónico', 0, 0, 0), -- LEAF
  (2166, 'Rock triste', 0, 0, 0), -- LEAF
  (2167, 'Rock urbano español', 0, 0, 0), -- LEAF
  (2168, 'Rock urbano mexicano', 0, 0, 0), -- LEAF
  (2169, 'Rockabilly', 0, 2, 1), -- 2 children
  (2170, 'Rocksteady', 0, 0, 0), -- LEAF
  (2171, 'Rom kbach', 0, 0, 0), -- LEAF
  (2172, 'Roman School', 0, 0, 0), -- LEAF
  (2173, 'Romance', 0, 0, 0), -- LEAF
  (2174, 'Romani Folk Music', 0, 0, 0), -- LEAF
  (2175, 'Romanian Etno Music', 0, 0, 0), -- LEAF
  (2176, 'Romanian Folk Music', 0, 4, 0), -- 4 children
  (2177, 'Romanian Music', 0, 8, 0), -- 8 children
  (2178, 'Romanian Popcorn', 0, 0, 0), -- LEAF
  (2179, 'Romantic Flow', 0, 0, 0), -- LEAF
  (2180, 'Romanticism', 0, 4, 0), -- 4 children
  (2181, 'Romantische Oper', 0, 0, 0), -- LEAF
  (2182, 'Romanţe', 0, 0, 0), -- LEAF
  (2183, 'Rominimal', 0, 0, 0), -- LEAF
  (2184, 'Roots Reggae', 1, 1, 1), -- 1 children
  (2185, 'Roots Rock', 1, 2, 2), -- 2 children
  (2186, 'Rumba catalana', 0, 0, 0), -- LEAF
  (2187, 'Rumba cubana', 0, 1, 0), -- 1 children
  (2188, 'Rumba flamenca', 0, 0, 0), -- LEAF
  (2189, 'Rune Singing', 0, 1, 0), -- 1 children
  (2190, 'Russemusikk', 0, 0, 0), -- LEAF
  (2191, 'Russian Chanson', 0, 0, 0), -- LEAF
  (2192, 'Russian Folk Music', 0, 0, 0), -- LEAF
  (2193, 'Russian Music', 0, 5, 0), -- 5 children
  (2194, 'Russian Romance', 0, 0, 0), -- LEAF
  (2195, 'Ryukyuan Music', 0, 2, 0), -- 2 children
  (2196, 'Ryūkōka', 0, 0, 0), -- LEAF
  (2197, 'Rōkyoku', 0, 0, 0), -- LEAF
  (2198, 'Sa''idi', 0, 0, 0), -- LEAF
  (2199, 'Sacred Singing Circle', 0, 0, 0), -- LEAF
  (2200, 'Sacred Steel', 0, 0, 0), -- LEAF
  (2201, 'Saeta', 0, 0, 0), -- LEAF
  (2202, 'Sahrawi Music', 0, 0, 0), -- LEAF
  (2203, 'Saint Petersburg School', 0, 0, 0), -- LEAF
  (2204, 'Sakha Traditional Music', 0, 0, 0), -- LEAF
  (2205, 'Salegy', 0, 0, 0), -- LEAF
  (2206, 'Salsa', 0, 4, 0), -- 4 children
  (2207, 'Salsa choke', 0, 0, 0), -- LEAF
  (2208, 'Salsa dura', 0, 0, 0), -- LEAF
  (2209, 'Salsa romántica', 0, 0, 0), -- LEAF
  (2210, 'Saluang klasik', 0, 0, 0), -- LEAF
  (2211, 'Samba', 0, 21, 4), -- 21 children
  (2212, 'Samba de breque', 0, 0, 0), -- LEAF
  (2213, 'Samba de gafieira', 0, 0, 0), -- LEAF
  (2214, 'Samba de roda', 0, 0, 0), -- LEAF
  (2215, 'Samba de terreiro', 0, 0, 0), -- LEAF
  (2216, 'Samba Rap', 0, 0, 0), -- LEAF
  (2217, 'Samba Soul', 0, 0, 0), -- LEAF
  (2218, 'Samba-canção', 0, 0, 0), -- LEAF
  (2219, 'Samba-choro', 1, 0, 1), -- LEAF
  (2220, 'Samba-enredo', 0, 0, 0), -- LEAF
  (2221, 'Samba-exaltação', 0, 0, 0), -- LEAF
  (2222, 'Samba-jazz', 0, 0, 0), -- LEAF
  (2223, 'Samba-joia', 0, 0, 0), -- LEAF
  (2224, 'Samba-reggae', 0, 0, 0), -- LEAF
  (2225, 'Samba-rock', 2, 1, 2), -- 1 children
  (2226, 'Sambalanço', 0, 0, 0), -- LEAF
  (2227, 'Sambass', 0, 0, 0), -- LEAF
  (2228, 'Samoan Music', 0, 0, 0), -- LEAF
  (2229, 'Samoyedic Folk Music', 0, 0, 0), -- LEAF
  (2230, 'Sample Drill', 1, 0, 1), -- LEAF
  (2231, 'Samri', 0, 0, 0), -- LEAF
  (2232, 'San Diego Sound', 0, 0, 0), -- LEAF
  (2233, 'San Francisco Sound', 0, 1, 0), -- 1 children
  (2234, 'Sanjo', 0, 0, 0), -- LEAF
  (2235, 'Santería Music', 0, 0, 0), -- LEAF
  (2236, 'Santé engagé', 0, 0, 0), -- LEAF
  (2237, 'Sarala gee', 0, 0, 0), -- LEAF
  (2238, 'Sardana', 0, 0, 0), -- LEAF
  (2239, 'Sardinian Folk Music', 0, 2, 0), -- 2 children
  (2240, 'Sarum Chant', 0, 0, 0), -- LEAF
  (2241, 'Sass', 9, 0, 9), -- LEAF
  (2242, 'Satire', 4, 0, 4), -- LEAF
  (2243, 'Sawt', 0, 0, 0), -- LEAF
  (2244, 'Saya', 0, 0, 0), -- LEAF
  (2245, 'Scam Rap', 0, 0, 0), -- LEAF
  (2246, 'Scene', 0, 1, 0), -- 1 children
  (2247, 'Schlager', 0, 4, 0), -- 4 children
  (2248, 'Schottische', 0, 1, 0), -- 1 children
  (2249, 'Schranz', 0, 0, 0), -- LEAF
  (2250, 'Scots Song', 0, 0, 0), -- LEAF
  (2251, 'Scottish Country Dance Music', 0, 0, 0), -- LEAF
  (2252, 'Scottish Folk Music', 0, 8, 0), -- 8 children
  (2253, 'Scottish Folk Revival', 0, 0, 0), -- LEAF
  (2254, 'Scouse House', 0, 1, 0), -- 1 children
  (2255, 'Screamo', 6, 1, 11), -- 1 children
  (2256, 'Scrumpy and Western', 0, 0, 0), -- LEAF
  (2257, 'Scum Rock', 0, 0, 0), -- LEAF
  (2258, 'Sea Shanty', 1, 0, 1), -- LEAF
  (2259, 'Sean-nós', 0, 0, 0), -- LEAF
  (2260, 'Seapunk', 0, 0, 0), -- LEAF
  (2261, 'Second British Folk Revival', 0, 0, 0), -- LEAF
  (2262, 'Second Viennese School', 0, 0, 0), -- LEAF
  (2263, 'Second Wave of Detroit Techno', 0, 0, 0), -- LEAF
  (2264, 'Seggae', 0, 0, 0), -- LEAF
  (2265, 'Seinn nan salm', 0, 0, 0), -- LEAF
  (2266, 'Seishun Punk', 0, 0, 0), -- LEAF
  (2267, 'Semba', 0, 0, 0), -- LEAF
  (2268, 'Semi-Trot', 0, 0, 0), -- LEAF
  (2269, 'Sephardic Music', 0, 3, 0), -- 3 children
  (2270, 'Sequencer & Tracker', 4, 5, 5), -- 5 children
  (2271, 'Serbian Folk Music', 0, 0, 0), -- LEAF
  (2272, 'Serenade', 0, 1, 0), -- 1 children
  (2273, 'Seresta', 0, 0, 0), -- LEAF
  (2274, 'Serialism', 0, 1, 0), -- 1 children
  (2275, 'Sermons', 0, 0, 0), -- LEAF
  (2276, 'Sertanejo', 0, 8, 0), -- 8 children
  (2277, 'Sertanejo de raiz', 0, 1, 0), -- 1 children
  (2278, 'Sertanejo romântico', 0, 0, 0), -- LEAF
  (2279, 'Sertanejo universitário', 0, 3, 0), -- 3 children
  (2280, 'Seto leelo', 0, 0, 0), -- LEAF
  (2281, 'Sevdalinka', 0, 0, 0), -- LEAF
  (2282, 'Sevillanas', 0, 0, 0), -- LEAF
  (2283, 'Sexy Drill', 0, 0, 0), -- LEAF
  (2284, 'Seychelles & Mascarene Islands Music', 0, 10, 0), -- 10 children
  (2285, 'Shaabi', 0, 2, 0), -- 2 children
  (2286, 'Shabad kirtan', 0, 0, 0), -- LEAF
  (2287, 'Shaker Music', 0, 0, 0), -- LEAF
  (2288, 'Shan''ge', 0, 0, 0), -- LEAF
  (2289, 'Shangaan Electro', 0, 0, 0), -- LEAF
  (2290, 'Shaoxing Opera', 0, 0, 0), -- LEAF
  (2291, 'Shape Note Singing', 0, 0, 0), -- LEAF
  (2292, 'Shashmaqam', 0, 0, 0), -- LEAF
  (2293, 'Shatta', 0, 0, 0), -- LEAF
  (2294, 'Shehhi Music', 0, 0, 0), -- LEAF
  (2295, 'Shetland & Orkney Folk Music', 0, 0, 0), -- LEAF
  (2296, 'Shibuya-kei', 1, 2, 1), -- 2 children
  (2297, 'Shidaiqu', 0, 0, 0), -- LEAF
  (2298, 'Shilla', 0, 0, 0), -- LEAF
  (2299, 'Shilluk Music', 0, 0, 0), -- LEAF
  (2300, 'Shimokita-kei', 3, 0, 3), -- LEAF
  (2301, 'Shitgaze', 0, 0, 0), -- LEAF
  (2302, 'Shoegaze', 46, 0, 46), -- LEAF
  (2303, 'Shona Mbira Music', 0, 0, 0), -- LEAF
  (2304, 'Shona Music', 0, 2, 0), -- 2 children
  (2305, 'Shoor', 0, 0, 0), -- LEAF
  (2306, 'Show Tunes', 0, 0, 0), -- LEAF
  (2307, 'Shōmyō', 0, 0, 0), -- LEAF
  (2308, 'Siberian Punk', 0, 0, 0), -- LEAF
  (2309, 'Sichuan Opera', 0, 0, 0), -- LEAF
  (2310, 'Sierreño', 0, 1, 0), -- 1 children
  (2311, 'Siffleur', 0, 0, 0), -- LEAF
  (2312, 'Sigilkore', 1, 0, 1), -- LEAF
  (2313, 'Sinawi', 0, 0, 0), -- LEAF
  (2314, 'Sindhi Music', 0, 0, 0), -- LEAF
  (2315, 'Sinfonia concertante', 0, 0, 0), -- LEAF
  (2316, 'Singeli', 0, 0, 0), -- LEAF
  (2317, 'Singer-Songwriter', 68, 18, 68), -- 18 children
  (2318, 'Singspiel', 0, 0, 0), -- LEAF
  (2319, 'Sinhalese Folk Music', 0, 1, 0), -- 1 children
  (2320, 'Sissy Bounce', 0, 0, 0), -- LEAF
  (2321, 'Sitarsploitation', 0, 0, 0), -- LEAF
  (2322, 'Sizhu Music', 0, 4, 0), -- 4 children
  (2323, 'Ska', 1, 8, 8), -- 8 children
  (2324, 'Ska Punk', 4, 2, 6), -- 2 children
  (2325, 'Skacore', 3, 1, 4), -- 1 children
  (2326, 'Skate Punk', 8, 0, 8), -- LEAF
  (2327, 'Sketch Comedy', 1, 0, 1), -- LEAF
  (2328, 'Skiffle', 0, 0, 0), -- LEAF
  (2329, 'Skiladika', 0, 0, 0), -- LEAF
  (2330, 'Skinhead Reggae', 0, 0, 0), -- LEAF
  (2331, 'Skullstep', 0, 0, 0), -- LEAF
  (2332, 'Skweee', 1, 0, 1), -- LEAF
  (2333, 'Slack-Key Guitar', 0, 0, 0), -- LEAF
  (2334, 'Slacker Rock', 19, 1, 19), -- 1 children
  (2335, 'Slam Death Metal', 6, 0, 6), -- LEAF
  (2336, 'Slam Poetry', 0, 0, 0), -- LEAF
  (2337, 'Slap House', 0, 0, 0), -- LEAF
  (2338, 'Slavic Folk Music', 0, 33, 2), -- 33 children
  (2339, 'Sleaze Rock', 0, 0, 0), -- LEAF
  (2340, 'Slimepunk', 0, 0, 0), -- LEAF
  (2341, 'Slovak Folk Music', 0, 0, 0), -- LEAF
  (2342, 'Slovenian Folk Music', 0, 1, 0), -- 1 children
  (2343, 'Slowcore', 14, 0, 14), -- LEAF
  (2344, 'Slowed & Reverb', 0, 0, 0), -- LEAF
  (2345, 'Sludge Metal', 31, 1, 42), -- 1 children
  (2346, 'Slushwave', 1, 0, 1), -- LEAF
  (2347, 'Smooth Jazz', 1, 0, 1), -- LEAF
  (2348, 'Smooth Soul', 9, 0, 9), -- LEAF
  (2349, 'Snap', 1, 0, 1), -- LEAF
  (2350, 'Soca', 0, 5, 0), -- 5 children
  (2351, 'Soft Rock', 5, 2, 5), -- 2 children
  (2352, 'Soft Visual', 0, 0, 0), -- LEAF
  (2353, 'Soga Music', 0, 0, 0), -- LEAF
  (2354, 'Solonese Gamelan', 0, 0, 0), -- LEAF
  (2355, 'Somali Music', 0, 3, 0), -- 3 children
  (2356, 'Son calentano', 0, 0, 0), -- LEAF
  (2357, 'Son cubano', 0, 2, 0), -- 2 children
  (2358, 'Son de pascua', 0, 0, 0), -- LEAF
  (2359, 'Son huasteco', 0, 0, 0), -- LEAF
  (2360, 'Son istmeño', 0, 0, 0), -- LEAF
  (2361, 'Son jarocho', 0, 0, 0), -- LEAF
  (2362, 'Son montuno', 0, 0, 0), -- LEAF
  (2363, 'Son nica', 0, 0, 0), -- LEAF
  (2364, 'Sonata', 0, 0, 0), -- LEAF
  (2365, 'Songhai Music', 1, 0, 1), -- LEAF
  (2366, 'Songo', 0, 0, 0), -- LEAF
  (2367, 'Sonorism', 1, 0, 1), -- LEAF
  (2368, 'Sophisti-Pop', 9, 0, 9), -- LEAF
  (2369, 'Sotho-Tswana Folk Music', 0, 0, 0), -- LEAF
  (2370, 'Soukous', 0, 1, 0), -- 1 children
  (2371, 'Soul', 12, 12, 73), -- 12 children
  (2372, 'Soul Blues', 1, 0, 1), -- LEAF
  (2373, 'Soul Jazz', 4, 0, 4), -- LEAF
  (2374, 'Sound Art', 0, 0, 0), -- LEAF
  (2375, 'Sound Collage', 46, 2, 53), -- 2 children
  (2376, 'Sound Effects', 0, 3, 0), -- 3 children
  (2377, 'Sound Poetry', 2, 0, 2), -- LEAF
  (2378, 'SoundClown', 0, 0, 0), -- LEAF
  (2379, 'Soundtrack', 0, 6, 1), -- 6 children
  (2380, 'South American Music', 0, 224, 10), -- 224 children
  (2381, 'South Asian Classical Music', 0, 12, 5), -- 12 children
  (2382, 'South Asian Folk Music', 0, 26, 1), -- 26 children
  (2383, 'South Asian Music', 0, 63, 6), -- 63 children
  (2384, 'South Florida SoundCloud Rap', 0, 0, 0), -- LEAF
  (2385, 'Southeast Asian Classical Music', 0, 29, 0), -- 29 children
  (2386, 'Southeast Asian Folk Music', 1, 18, 1), -- 18 children
  (2387, 'Southeast Asian Music', 0, 115, 2), -- 115 children
  (2388, 'Southeastern Brazilian Music', 0, 17, 3), -- 17 children
  (2389, 'Southern African Folk Music', 0, 4, 0), -- 4 children
  (2390, 'Southern African Music', 0, 29, 0), -- 29 children
  (2391, 'Southern Brazilian Music', 0, 3, 0), -- 3 children
  (2392, 'Southern Gospel', 0, 0, 0), -- LEAF
  (2393, 'Southern Hip Hop', 6, 1, 6), -- 1 children
  (2394, 'Southern Metal', 0, 0, 0), -- LEAF
  (2395, 'Southern Rock', 0, 0, 0), -- LEAF
  (2396, 'Southern Soul', 1, 0, 1), -- LEAF
  (2397, 'Soviet Estrada', 0, 0, 0), -- LEAF
  (2398, 'Sovietwave', 0, 0, 0), -- LEAF
  (2399, 'Space Age Pop', 7, 0, 7), -- LEAF
  (2400, 'Space Ambient', 6, 0, 6), -- LEAF
  (2401, 'Space Disco', 0, 0, 0), -- LEAF
  (2402, 'Space Rock', 4, 1, 14), -- 1 children
  (2403, 'Space Rock Revival', 10, 0, 10), -- LEAF
  (2404, 'Spacesynth', 0, 1, 0), -- 1 children
  (2405, 'Spaghetti Western', 1, 0, 1), -- LEAF
  (2406, 'Spanish Classical Music', 0, 5, 0), -- 5 children
  (2407, 'Spanish Folk Music', 0, 13, 0), -- 13 children
  (2408, 'Spanish Music', 0, 31, 1), -- 31 children
  (2409, 'Spectralism', 0, 0, 0), -- LEAF
  (2410, 'Speeches', 0, 1, 0), -- 1 children
  (2411, 'Speed Garage', 1, 0, 1), -- LEAF
  (2412, 'Speed House', 1, 0, 1), -- LEAF
  (2413, 'Speed Metal', 1, 0, 1), -- LEAF
  (2414, 'Speedcore', 4, 2, 4), -- 2 children
  (2415, 'Spiritual', 0, 3, 0), -- 3 children
  (2416, 'Spiritual Art Song', 0, 0, 0), -- LEAF
  (2417, 'Spiritual Jazz', 12, 0, 12), -- LEAF
  (2418, 'Spirituals', 3, 0, 3), -- LEAF
  (2419, 'Splittercore', 2, 0, 2), -- LEAF
  (2420, 'Spoken Word', 30, 17, 39), -- 17 children
  (2421, 'Spouge', 0, 0, 0), -- LEAF
  (2422, 'Spy Music', 0, 0, 0), -- LEAF
  (2423, 'Stand-Up Comedy', 0, 0, 0), -- LEAF
  (2424, 'Standards', 0, 0, 0), -- LEAF
  (2425, 'Starogradska muzika', 0, 1, 0), -- 1 children
  (2426, 'Staïfi', 0, 0, 0), -- LEAF
  (2427, 'Steel Band', 0, 0, 0), -- LEAF
  (2428, 'Stenchcore', 1, 0, 1), -- LEAF
  (2429, 'Stereo', 0, 0, 0), -- LEAF
  (2430, 'Stochastic Music', 0, 0, 0), -- LEAF
  (2431, 'Stomp and Holler', 0, 0, 0), -- LEAF
  (2432, 'Stoner Metal', 10, 0, 10), -- LEAF
  (2433, 'Stoner Rap', 0, 0, 0), -- LEAF
  (2434, 'Stoner Rock', 3, 0, 3), -- LEAF
  (2435, 'Stornello', 0, 0, 0), -- LEAF
  (2436, 'Straight Edge', 0, 5, 0), -- 5 children
  (2437, 'Street Punk', 1, 0, 1), -- LEAF
  (2438, 'Stride', 0, 0, 0), -- LEAF
  (2439, 'String Quartet', 0, 0, 0), -- LEAF
  (2440, 'Stutter House', 0, 0, 0), -- LEAF
  (2441, 'Sufi Music', 0, 8, 1), -- 8 children
  (2442, 'Sufi Rock', 0, 0, 0), -- LEAF
  (2443, 'Sufiana kalam', 0, 0, 0), -- LEAF
  (2444, 'Sundanese Music', 0, 8, 0), -- 8 children
  (2445, 'Sungura', 0, 0, 0), -- LEAF
  (2446, 'Sunset Strip Glam Metal', 0, 0, 0), -- LEAF
  (2447, 'Sunshine Pop', 3, 0, 3), -- LEAF
  (2448, 'Suomisaundi', 0, 0, 0), -- LEAF
  (2449, 'Surf Music', 1, 8, 5), -- 8 children
  (2450, 'Surf Punk', 0, 0, 0), -- LEAF
  (2451, 'Surf Rock', 2, 3, 2), -- 3 children
  (2452, 'Sutartinės', 0, 0, 0), -- LEAF
  (2453, 'Swamp Blues', 0, 0, 0), -- LEAF
  (2454, 'Swamp Pop', 0, 0, 0), -- LEAF
  (2455, 'Swamp Rock', 0, 0, 0), -- LEAF
  (2456, 'Swancore', 1, 0, 1), -- LEAF
  (2457, 'Swedish Folk Music', 0, 1, 0), -- 1 children
  (2458, 'Sweet Jazz', 0, 0, 0), -- LEAF
  (2459, 'Swing', 0, 1, 0), -- 1 children
  (2460, 'Swing musette', 0, 0, 0), -- LEAF
  (2461, 'Swing Revival', 0, 0, 0), -- LEAF
  (2462, 'Symphonic Black Metal', 2, 0, 2), -- LEAF
  (2463, 'Symphonic Metal', 2, 0, 2), -- LEAF
  (2464, 'Symphonic Mugham', 0, 0, 0), -- LEAF
  (2465, 'Symphonic Prog', 1, 0, 1), -- LEAF
  (2466, 'Symphonic Rock', 0, 0, 0), -- LEAF
  (2467, 'Symphony', 0, 2, 0), -- 2 children
  (2468, 'Synth Funk', 17, 1, 19), -- 1 children
  (2469, 'Synth Punk', 12, 0, 12), -- LEAF
  (2470, 'Synthpop', 29, 3, 29), -- 3 children
  (2471, 'Synthwave', 3, 4, 5), -- 4 children
  (2472, 'Syriac Chant', 0, 0, 0), -- LEAF
  (2473, 'Séga', 0, 3, 0), -- 3 children
  (2474, 'Séga tambour', 0, 0, 0), -- LEAF
  (2475, 'Sōkyoku', 0, 2, 0), -- 2 children
  (2476, 'T-Pop', 0, 0, 0), -- LEAF
  (2477, 'Taarab', 0, 1, 0), -- 1 children
  (2478, 'Tahitian Music', 0, 1, 0), -- 1 children
  (2479, 'Taiko', 0, 0, 0), -- LEAF
  (2480, 'Tajik Music', 0, 0, 0), -- LEAF
  (2481, 'Takamba', 0, 0, 0), -- LEAF
  (2482, 'Talempong', 0, 0, 0), -- LEAF
  (2483, 'Talempong goyang', 0, 0, 0), -- LEAF
  (2484, 'Talking Blues', 0, 0, 0), -- LEAF
  (2485, 'Tallava', 0, 0, 0), -- LEAF
  (2486, 'Tamborera', 0, 0, 0), -- LEAF
  (2487, 'Tamborito', 0, 0, 0), -- LEAF
  (2488, 'Tamborzão', 2, 0, 2), -- LEAF
  (2489, 'Tamil Folk Music', 0, 1, 1), -- 1 children
  (2490, 'Tammurriata', 0, 0, 0), -- LEAF
  (2491, 'Tango', 0, 2, 0), -- 2 children
  (2492, 'Tango Nuevo', 0, 0, 0), -- LEAF
  (2493, 'Tanjidor', 0, 0, 0), -- LEAF
  (2494, 'Taoist Ritual Music', 0, 0, 0), -- LEAF
  (2495, 'Tape Music', 15, 0, 15), -- LEAF
  (2496, 'Taquirari', 0, 0, 0), -- LEAF
  (2497, 'Taqwacore', 0, 0, 0), -- LEAF
  (2498, 'Tarana', 0, 0, 0), -- LEAF
  (2499, 'Tarantella', 0, 2, 0), -- 2 children
  (2500, 'Tarawangsa', 0, 0, 0), -- LEAF
  (2501, 'Tarraxinha', 0, 0, 0), -- LEAF
  (2502, 'Tarz', 0, 0, 0), -- LEAF
  (2503, 'Tassa', 0, 0, 0), -- LEAF
  (2504, 'Tassu', 0, 0, 0), -- LEAF
  (2505, 'TBM', 0, 0, 0), -- LEAF
  (2506, 'Tchink System', 0, 0, 0), -- LEAF
  (2507, 'Tchinkoumé', 0, 0, 0), -- LEAF
  (2508, 'Tearout', 0, 0, 0), -- LEAF
  (2509, 'Tearout [Brostep]', 1, 0, 1), -- LEAF
  (2510, 'Tech House', 6, 2, 6), -- 2 children
  (2511, 'Tech Trance', 1, 0, 1), -- LEAF
  (2512, 'Technical Death Metal', 17, 1, 21), -- 1 children
  (2513, 'Technical Thrash Metal', 2, 0, 2), -- LEAF
  (2514, 'Techno', 8, 18, 35), -- 18 children
  (2515, 'Techno Bass', 0, 1, 0), -- 1 children
  (2516, 'Techno kayō', 0, 0, 0), -- LEAF
  (2517, 'Technoid', 0, 0, 0), -- LEAF
  (2518, 'Techstep', 0, 0, 0), -- LEAF
  (2519, 'Tecktonik', 0, 0, 0), -- LEAF
  (2520, 'Tecnobanda', 0, 0, 0), -- LEAF
  (2521, 'Tecnobrega', 0, 3, 0), -- 3 children
  (2522, 'Tecnofunk', 0, 0, 0), -- LEAF
  (2523, 'Tecnomerengue', 0, 0, 0), -- LEAF
  (2524, 'Tecnorumba', 0, 0, 0), -- LEAF
  (2525, 'Teen Pop', 0, 0, 0), -- LEAF
  (2526, 'Tejano Music', 0, 0, 0), -- LEAF
  (2527, 'Television Music', 0, 0, 0), -- LEAF
  (2528, 'Telugu Folk Music', 0, 1, 0), -- 1 children
  (2529, 'Tembang Sunda Cianjuran', 0, 0, 0), -- LEAF
  (2530, 'Terror Plugg', 1, 0, 1), -- LEAF
  (2531, 'Terrorcore', 3, 0, 3), -- LEAF
  (2532, 'Teutonic Thrash Metal', 0, 0, 0), -- LEAF
  (2533, 'Tex-Mex', 1, 0, 1), -- LEAF
  (2534, 'Texan Music', 0, 4, 1), -- 4 children
  (2535, 'Texas Psychedelia', 0, 0, 0), -- LEAF
  (2536, 'Thai Classical Music', 0, 3, 0), -- 3 children
  (2537, 'Thai Folk Music', 0, 1, 0), -- 1 children
  (2538, 'Thai Music', 1, 11, 1), -- 11 children
  (2539, 'Thall', 0, 0, 0), -- LEAF
  (2540, 'The Batcave', 0, 0, 0), -- LEAF
  (2541, 'The New Thing', 0, 0, 0), -- LEAF
  (2542, 'The Sound of Young Scotland', 0, 0, 0), -- LEAF
  (2543, 'The Wave', 0, 0, 0), -- LEAF
  (2544, 'Theme and Variation', 0, 0, 0), -- LEAF
  (2545, 'Third Stream', 5, 0, 5), -- LEAF
  (2546, 'Third Wave Ska', 3, 3, 7), -- 3 children
  (2547, 'Thrash Metal', 4, 2, 7), -- 2 children
  (2548, 'Thrashcore', 1, 1, 12), -- 1 children
  (2549, 'Thumri', 1, 0, 1), -- LEAF
  (2550, 'Tibetan Buddhist Chant', 0, 0, 0), -- LEAF
  (2551, 'Tibetan Music', 0, 3, 0), -- 3 children
  (2552, 'Tibetan New Age', 0, 0, 0), -- LEAF
  (2553, 'Tigrinya Music', 0, 0, 0), -- LEAF
  (2554, 'Timba', 0, 0, 0), -- LEAF
  (2555, 'Timbila', 0, 0, 0), -- LEAF
  (2556, 'Tin Pan Alley', 0, 0, 0), -- LEAF
  (2557, 'Tishoumaren', 0, 0, 0), -- LEAF
  (2558, 'Tivaner inngernerlu', 0, 0, 0), -- LEAF
  (2559, 'Tizita', 0, 0, 0), -- LEAF
  (2560, 'Toada de Boi', 0, 0, 0), -- LEAF
  (2561, 'Toccata', 0, 0, 0), -- LEAF
  (2562, 'Tolai Rock', 0, 0, 0), -- LEAF
  (2563, 'Tonada chilena', 0, 0, 0), -- LEAF
  (2564, 'Tonada potosina', 0, 0, 0), -- LEAF
  (2565, 'Tondero', 0, 0, 0), -- LEAF
  (2566, 'Tone Poem', 0, 0, 0), -- LEAF
  (2567, 'Tontipop', 0, 0, 0), -- LEAF
  (2568, 'Topanga Canyon Scene', 0, 0, 0), -- LEAF
  (2569, 'Tosk Polyphony', 0, 0, 0), -- LEAF
  (2570, 'Totalism', 6, 0, 6), -- LEAF
  (2571, 'Touhou Music', 0, 0, 0), -- LEAF
  (2572, 'Township Bubblegum', 0, 0, 0), -- LEAF
  (2573, 'Township Jive', 0, 0, 0), -- LEAF
  (2574, 'Toypop', 1, 0, 1), -- LEAF
  (2575, 'Toytown Pop', 0, 0, 0), -- LEAF
  (2576, 'Tracker Music', 1, 3, 1), -- 3 children
  (2577, 'Tradi-moderne congolais', 0, 0, 0), -- LEAF
  (2578, 'Tradi-moderne ivoirien', 0, 0, 0), -- LEAF
  (2579, 'Traditional Black Gospel', 0, 0, 0), -- LEAF
  (2580, 'Traditional Bluegrass', 0, 1, 0), -- 1 children
  (2581, 'Traditional Cajun Music', 0, 0, 0), -- LEAF
  (2582, 'Traditional Country', 0, 5, 0), -- 5 children
  (2583, 'Traditional Doom Metal', 1, 1, 2), -- 1 children
  (2584, 'Traditional Folk Music', 1, 444, 22), -- 444 children
  (2585, 'Traditional Maloya', 0, 0, 0), -- LEAF
  (2586, 'Traditional Pop', 1, 5, 1), -- 5 children
  (2587, 'Traditional Raï', 0, 0, 0), -- LEAF
  (2588, 'Traditional Séga', 0, 1, 0), -- 1 children
  (2589, 'Tragédie en musique', 0, 0, 0), -- LEAF
  (2590, 'Trallalero', 0, 0, 0), -- LEAF
  (2591, 'Trampská hudba', 0, 0, 0), -- LEAF
  (2592, 'Trance', 2, 27, 9), -- 27 children
  (2593, 'Trance 2.0', 0, 0, 0), -- LEAF
  (2594, 'Trance Metal', 0, 0, 0), -- LEAF
  (2595, 'Trancestep', 0, 0, 0), -- LEAF
  (2596, 'Trap', 34, 21, 49), -- 21 children
  (2597, 'Trap [EDM]', 2, 5, 4), -- 5 children
  (2598, 'Trap Dancehall', 0, 0, 0), -- LEAF
  (2599, 'Trap latino', 0, 0, 0), -- LEAF
  (2600, 'Trap Metal', 6, 0, 6), -- LEAF
  (2601, 'Trap shaabi', 0, 0, 0), -- LEAF
  (2602, 'Trap Soul', 2, 0, 2), -- LEAF
  (2603, 'Trap[EDM]', 1, 0, 1), -- LEAF
  (2604, 'Trapfunk', 0, 0, 0), -- LEAF
  (2605, 'Tread', 1, 0, 1), -- LEAF
  (2606, 'Tribal Ambient', 11, 0, 11), -- LEAF
  (2607, 'Tribal Guarachero', 0, 0, 0), -- LEAF
  (2608, 'Tribal House', 0, 1, 0), -- 1 children
  (2609, 'Trinidadian Cariso', 0, 0, 0), -- LEAF
  (2610, 'Trip Hop', 13, 0, 13), -- LEAF
  (2611, 'Tropical House', 0, 0, 0), -- LEAF
  (2612, 'Tropical Rock', 1, 0, 1), -- LEAF
  (2613, 'Tropicanibalismo', 0, 0, 0), -- LEAF
  (2614, 'Tropicália', 1, 0, 1), -- LEAF
  (2615, 'Tropipop', 0, 0, 0), -- LEAF
  (2616, 'Trot', 0, 2, 0), -- 2 children
  (2617, 'Trova', 0, 1, 0), -- 1 children
  (2618, 'Trova rosarina', 0, 0, 0), -- LEAF
  (2619, 'Trova yucateca', 0, 0, 0), -- LEAF
  (2620, 'Truck Driving Country', 0, 0, 0), -- LEAF
  (2621, 'Trás-os-Montes Folk Music', 0, 0, 0), -- LEAF
  (2622, 'Tsapiky', 0, 0, 0), -- LEAF
  (2623, 'Tsonga Disco', 0, 0, 0), -- LEAF
  (2624, 'Tsugaru Shamisen', 0, 0, 0), -- LEAF
  (2625, 'Tuareg Music', 0, 2, 0), -- 2 children
  (2626, 'Tumba', 0, 0, 0), -- LEAF
  (2627, 'Tumba francesa', 0, 0, 0), -- LEAF
  (2628, 'Tumbélé', 0, 0, 0), -- LEAF
  (2629, 'Tunantada', 0, 0, 0), -- LEAF
  (2630, 'Turbo-Folk', 0, 0, 0), -- LEAF
  (2631, 'Turkic-Mongolic Music', 0, 16, 1), -- 16 children
  (2632, 'Turkish Black Sea Region Folk Music', 0, 0, 0), -- LEAF
  (2633, 'Turkish Classical Music', 0, 1, 0), -- 1 children
  (2634, 'Turkish Folk Music', 0, 3, 0), -- 3 children
  (2635, 'Turkish Mevlevi Music', 0, 0, 0), -- LEAF
  (2636, 'Turkish Music', 0, 13, 1), -- 13 children
  (2637, 'Turkish Pop', 0, 0, 0), -- LEAF
  (2638, 'Turkmen Music', 0, 0, 0), -- LEAF
  (2639, 'Turntable Music', 2, 0, 2), -- LEAF
  (2640, 'Turntablism', 6, 0, 6), -- LEAF
  (2642, 'Tuvan Throat Singing', 1, 0, 1), -- LEAF
  (2643, 'Twa Music', 0, 0, 0), -- LEAF
  (2644, 'Twee Pop', 5, 1, 6), -- 1 children
  (2645, 'Twelve Muqam', 0, 0, 0), -- LEAF
  (2646, 'Twerk', 0, 0, 0), -- LEAF
  (2647, 'Twist', 0, 0, 0), -- LEAF
  (2648, 'Twoubadou', 0, 0, 0), -- LEAF
  (2649, 'Tân cổ giao duyên', 0, 0, 0), -- LEAF
  (2650, 'Uaajeerneq', 0, 0, 0), -- LEAF
  (2651, 'Udigrudi', 1, 0, 1), -- LEAF
  (2652, 'Udmurt Folk Music', 0, 0, 0), -- LEAF
  (2653, 'UK Bass', 10, 0, 10), -- LEAF
  (2654, 'UK Drill', 1, 0, 1), -- LEAF
  (2655, 'UK Funky', 0, 0, 0), -- LEAF
  (2656, 'UK Garage', 1, 6, 5), -- 6 children
  (2657, 'UK Hard House', 0, 3, 1), -- 3 children
  (2658, 'UK Hardcore', 0, 2, 0), -- 2 children
  (2659, 'UK Hip Hop', 4, 0, 4), -- LEAF
  (2660, 'UK Jackin''', 0, 0, 0), -- LEAF
  (2661, 'UK Street Soul', 0, 0, 0), -- LEAF
  (2662, 'UK82', 1, 0, 1), -- LEAF
  (2663, 'Ukrainian Folk Music', 1, 2, 1), -- 2 children
  (2664, 'Ultra', 0, 0, 0), -- LEAF
  (2665, 'Ultra Metal', 0, 0, 0), -- LEAF
  (2666, 'Umeå Hardcore', 0, 0, 0), -- LEAF
  (2667, 'Unakesa', 0, 0, 0), -- LEAF
  (2668, 'Uncategorised', 0, 128, 122), -- 128 children
  (2669, 'Unyago', 0, 0, 0), -- LEAF
  (2670, 'Uplifting Trance', 0, 0, 0), -- LEAF
  (2671, 'Upopo', 0, 0, 0), -- LEAF
  (2672, 'Uptempo Hardcore', 0, 0, 0), -- LEAF
  (2673, 'Urban Contemporary Gospel', 0, 0, 0), -- LEAF
  (2674, 'Urban Cowboy', 0, 0, 0), -- LEAF
  (2675, 'Urban Grooves', 0, 0, 0), -- LEAF
  (2676, 'Urtiin duu', 0, 0, 0), -- LEAF
  (2677, 'Urumi melam', 1, 0, 1), -- LEAF
  (2678, 'US Power Metal', 0, 0, 0), -- LEAF
  (2679, 'Utaite', 0, 0, 0), -- LEAF
  (2680, 'Utopian Virtual', 4, 0, 4), -- LEAF
  (2681, 'Uyghur Music', 0, 2, 0), -- 2 children
  (2682, 'Uzbek Music', 0, 0, 0), -- LEAF
  (2683, 'Uzun Hava', 0, 0, 0), -- LEAF
  (2684, 'V-Pop', 0, 0, 0), -- LEAF
  (2685, 'Vaigat', 0, 0, 0), -- LEAF
  (2686, 'Valencian Folk Music', 0, 0, 0), -- LEAF
  (2687, 'Vallenato', 0, 0, 0), -- LEAF
  (2688, 'Vals criollo', 0, 0, 0), -- LEAF
  (2689, 'Vals venezolano', 0, 0, 0), -- LEAF
  (2690, 'Valsa brasileira', 0, 0, 0), -- LEAF
  (2691, 'Vanera', 0, 0, 0), -- LEAF
  (2692, 'Vanguarda paulista', 0, 0, 0), -- LEAF
  (2693, 'Vapor', 3, 12, 14), -- 12 children
  (2694, 'Vapornoise', 1, 0, 1), -- LEAF
  (2695, 'Vaportrap', 0, 0, 0), -- LEAF
  (2696, 'Vaporwave', 8, 4, 8), -- 4 children
  (2697, 'Vaudeville', 0, 1, 0), -- 1 children
  (2698, 'Vaudeville Blues', 0, 0, 0), -- LEAF
  (2699, 'Vedic Chant', 0, 0, 0), -- LEAF
  (2700, 'Vegan Straight Edge', 0, 2, 0), -- 2 children
  (2701, 'Verismo', 0, 0, 0), -- LEAF
  (2702, 'Video Game Music', 0, 0, 0), -- LEAF
  (2703, 'Vietnamese Court Music', 0, 1, 0), -- 1 children
  (2704, 'Vietnamese Folk Music', 0, 3, 0), -- 3 children
  (2705, 'Vietnamese Music', 0, 15, 0), -- 15 children
  (2706, 'Vietnamese New Wave', 0, 0, 0), -- LEAF
  (2707, 'Vietnamese Opera', 0, 0, 0), -- LEAF
  (2708, 'Viking Metal', 0, 0, 0), -- LEAF
  (2709, 'Vikingarock', 0, 0, 0), -- LEAF
  (2710, 'Villancico', 0, 0, 0), -- LEAF
  (2711, 'Vinahouse', 0, 0, 0), -- LEAF
  (2712, 'Vira', 0, 0, 0), -- LEAF
  (2713, 'Virgin Islander Cariso', 0, 0, 0), -- LEAF
  (2714, 'Visa', 0, 0, 0), -- LEAF
  (2715, 'Visual kei', 0, 3, 0), -- 3 children
  (2716, 'Vixa', 0, 0, 0), -- LEAF
  (2717, 'Vocal Group', 0, 3, 3), -- 3 children
  (2718, 'Vocal Jazz', 2, 1, 2), -- 1 children
  (2719, 'Vocal Surf', 1, 0, 1), -- LEAF
  (2720, 'Vocal Trance', 0, 0, 0), -- LEAF
  (2721, 'Vocalese', 0, 0, 0), -- LEAF
  (2722, 'Vocaloid Scene', 0, 1, 0), -- 1 children
  (2723, 'Volga Tatar Folk Music', 0, 0, 0), -- LEAF
  (2724, 'Volga-Ural Folk Music', 0, 7, 0), -- 7 children
  (2725, 'Volkstümliche Musik', 0, 0, 0), -- LEAF
  (2726, 'Voëlvry Movement', 0, 0, 0), -- LEAF
  (2727, 'Vude', 0, 0, 0), -- LEAF
  (2728, 'Wa Euro', 0, 1, 0), -- 1 children
  (2729, 'Waila', 0, 0, 0), -- LEAF
  (2730, 'Waka', 0, 0, 0), -- LEAF
  (2731, 'Walloon Folk Music', 0, 0, 0), -- LEAF
  (2732, 'Waltz', 0, 2, 0), -- 2 children
  (2733, 'Wangga', 0, 0, 0), -- LEAF
  (2734, 'War Metal', 3, 0, 3), -- LEAF
  (2735, 'Warez Scene', 0, 0, 0), -- LEAF
  (2736, 'Warsaw City Folk', 0, 0, 0), -- LEAF
  (2737, 'Wassoulou', 0, 0, 0), -- LEAF
  (2738, 'Wave', 6, 2, 6), -- 2 children
  (2739, 'Weightless', 0, 0, 0), -- LEAF
  (2740, 'Welayta Music', 0, 0, 0), -- LEAF
  (2741, 'Welsh Folk Music', 0, 0, 0), -- LEAF
  (2742, 'West African Music', 1, 47, 4), -- 47 children
  (2743, 'West Asian Folk Music', 0, 14, 0), -- 14 children
  (2744, 'West Asian Music', 0, 68, 1), -- 68 children
  (2745, 'West Coast Breaks', 0, 0, 0), -- LEAF
  (2746, 'West Coast Hip Hop', 12, 1, 12), -- 1 children
  (2747, 'West Coast Jazz', 1, 0, 1), -- LEAF
  (2748, 'West Coast Sound of Holland', 0, 0, 0), -- LEAF
  (2749, 'West Side Sound', 0, 0, 0), -- LEAF
  (2750, 'Western', 0, 0, 0), -- LEAF
  (2751, 'Western Classical Music', 1, 122, 53), -- 122 children
  (2752, 'Western Swing', 0, 0, 0), -- LEAF
  (2753, 'Whale Song', 0, 0, 0), -- LEAF
  (2754, 'White Voice', 1, 0, 1), -- LEAF
  (2755, 'Windmill Scene', 0, 0, 0), -- LEAF
  (2756, 'Winter Synth', 1, 0, 1), -- LEAF
  (2757, 'Witch House', 9, 0, 9), -- LEAF
  (2758, 'Wizard Rock', 0, 0, 0), -- LEAF
  (2759, 'Wolof Music', 0, 2, 0), -- 2 children
  (2760, 'Women''s Music Movement', 0, 0, 0), -- LEAF
  (2761, 'Wong shadow', 0, 0, 0), -- LEAF
  (2762, 'Wonky', 13, 1, 13), -- 1 children
  (2763, 'Wonky Techno', 6, 0, 6), -- LEAF
  (2764, 'Work Song', 0, 8, 1), -- 8 children
  (2765, 'Worldbeat', 0, 0, 0), -- LEAF
  (2766, 'Wyrd Folk', 1, 0, 1), -- LEAF
  (2767, 'Xaxado', 1, 0, 1), -- LEAF
  (2768, 'Xian Psych', 0, 0, 0), -- LEAF
  (2769, 'Xibei feng', 0, 0, 0), -- LEAF
  (2770, 'Xinyao', 0, 0, 0), -- LEAF
  (2771, 'Xote', 0, 0, 0), -- LEAF
  (2772, 'Xtra Raw', 0, 0, 0), -- LEAF
  (2773, 'Xuc', 0, 0, 0), -- LEAF
  (2774, 'Xẩm', 0, 0, 0), -- LEAF
  (2775, 'Yacht Rock', 0, 0, 0), -- LEAF
  (2776, 'Yakousei', 0, 0, 0), -- LEAF
  (2777, 'Yangzhou Opera', 0, 0, 0), -- LEAF
  (2778, 'Yanyue', 0, 0, 0), -- LEAF
  (2779, 'Yaraví', 0, 0, 0), -- LEAF
  (2780, 'Yass', 0, 0, 0), -- LEAF
  (2781, 'Yayue', 0, 0, 0), -- LEAF
  (2782, 'Yemenite Jewish Diwan', 0, 0, 0), -- LEAF
  (2783, 'Yiddish Folksong', 0, 0, 0), -- LEAF
  (2784, 'Yodeling', 0, 2, 0), -- 2 children
  (2785, 'Yoruba Folk Opera', 0, 0, 0), -- LEAF
  (2786, 'Yoruba Music', 0, 6, 0), -- 6 children
  (2787, 'Youth Crew', 0, 0, 0), -- LEAF
  (2788, 'YTPMV', 0, 1, 0), -- 1 children
  (2789, 'Yu-Mex', 0, 0, 0), -- LEAF
  (2790, 'Yugoslav New Wave', 0, 0, 0), -- LEAF
  (2791, 'Yukar', 0, 0, 0), -- LEAF
  (2792, 'Yé-yé', 0, 0, 0), -- LEAF
  (2793, 'Zajal', 0, 0, 0), -- LEAF
  (2794, 'Zamacueca', 0, 0, 0), -- LEAF
  (2795, 'Zamba', 0, 0, 0), -- LEAF
  (2796, 'Zamrock', 0, 0, 0), -- LEAF
  (2797, 'Zarzuela', 0, 3, 0), -- 3 children
  (2798, 'Zarzuela barroca', 0, 0, 0), -- LEAF
  (2799, 'Zarzuela grande', 0, 0, 0), -- LEAF
  (2800, 'Zeitoper', 0, 0, 0), -- LEAF
  (2801, 'Zemirot', 0, 0, 0), -- LEAF
  (2802, 'Zenonesque', 0, 0, 0), -- LEAF
  (2803, 'Zess', 0, 0, 0), -- LEAF
  (2804, 'Zeuhl', 5, 0, 5), -- LEAF
  (2805, 'Zeybek', 0, 0, 0), -- LEAF
  (2806, 'Zhabdro gorgom', 0, 0, 0), -- LEAF
  (2807, 'Zhongguo feng', 0, 0, 0), -- LEAF
  (2808, 'Ziglibithy', 0, 0, 0), -- LEAF
  (2809, 'Zimdancehall', 0, 0, 0), -- LEAF
  (2810, 'Zinli', 0, 0, 0), -- LEAF
  (2811, 'Znamenny Chant', 0, 0, 0), -- LEAF
  (2812, 'Zoblazo', 0, 0, 0), -- LEAF
  (2813, 'Zohioliin duu', 0, 0, 0), -- LEAF
  (2814, 'Zolo', 7, 0, 7), -- LEAF
  (2815, 'Zouglou', 0, 1, 0), -- 1 children
  (2816, 'Zouk', 0, 2, 0), -- 2 children
  (2817, 'Zouk Love', 0, 0, 0), -- LEAF
  (2818, 'Zydeco', 0, 1, 0), -- 1 children
  (2819, 'Étude', 0, 0, 0), -- LEAF
  (2820, 'Òrain Ghàidhlig', 0, 2, 0), -- 2 children
  (2821, 'Òrain luaidh', 0, 0, 0), -- LEAF
  (2822, 'Özgün Müzik', 0, 0, 0), -- LEAF
  (2823, 'Čalgija', 0, 0, 0), -- LEAF
  (2824, 'Česká alternativní scéna', 0, 0, 0), -- LEAF
  (2825, 'Česká nová vlna', 0, 0, 0), -- LEAF
  (2826, 'Český underground', 0, 0, 0), -- LEAF
  (2827, 'Berlin Techno', 0, 0, 0), -- LEAF
  (2828, 'Toytown Techno', 0, 0, 0), -- LEAF
  (2829, 'Epic House', 0, 0, 0), -- LEAF
  (2830, 'Jungle Techno', 0, 0, 0), -- LEAF
  (2831, 'Detroit Trap', 0, 0, 0), -- LEAF
  (2832, 'Dungeon Chip', 0, 0, 0), -- LEAF
  (2833, 'Hard Renaissance', 0, 0, 0), -- LEAF
  (2834, 'New London Silence', 0, 0, 0), -- LEAF
  (2835, 'Budget Rock', 0, 0, 0), -- LEAF
  (2836, 'Brumbeat', 0, 0, 0), -- LEAF
  (2837, 'Tough Guy Hardcore', 0, 0, 0), -- LEAF
  (2838, 'Los Angeles Hardcore', 0, 0, 0), -- LEAF
  (2839, 'Rustic Stomp', 0, 0, 0), -- LEAF
  (2840, 'Operatic Pop', 0, 0, 0), -- LEAF
  (2841, 'VTuber Music', 0, 0, 0), -- LEAF
  (2842, 'Gospel Hymn', 0, 0, 0), -- LEAF
  (2843, 'Partyschlager', 0, 0, 0), -- LEAF
  (2844, 'Trikitixa', 0, 0, 0), -- LEAF
  (2845, 'Valaam Chant', 0, 0, 0), -- LEAF
  (2846, 'Dohori', 0, 0, 0), -- LEAF
  (2847, 'Chuscada', 0, 0, 0), -- LEAF
  (2848, 'Guayla', 0, 0, 0), -- LEAF
  (2849, 'M''godro', 0, 0, 0), -- LEAF
  (2850, 'Bedoui wahrani', 0, 0, 0), -- LEAF
  (2851, 'Jhumar', 0, 0, 0), -- LEAF
  (2852, 'Dongzu dage', 0, 0, 0), -- LEAF
  (2853, 'Du ca', 0, 0, 0), -- LEAF
  (2854, 'Huayno con Arpa', 0, 0, 0), -- LEAF
  (2855, 'Cumbia sureña peruana', 0, 0, 0), -- LEAF
  (2856, 'La Onda', 0, 0, 0), -- LEAF
  (2857, 'Chakacha', 0, 0, 0), -- LEAF
  (2858, 'Echtzeitmusik', 0, 0, 0), -- LEAF
  (2859, 'Pimp Rap', 0, 0, 0), -- LEAF
  (2860, 'Sao Paulo Queer Underground', 0, 0, 0)  -- LEAF;


-- =============================================================================
-- 2. GENRE TREE (genre_hierarchy) - every single edge
-- =============================================================================
-- Each row is one parent->child edge of the genre tree. The parent column has
-- the parent node id, child the child node id; the name comments spell out the
-- relationship in plain English so the full tree is readable without looking
-- ids up.
INSERT INTO public.genre_hierarchy (parent_genre_id, child_genre_id) VALUES
  (6, 423), -- A cappella  ->  Canto cardenche
  (6, 525), -- A cappella  ->  Choral Concerto
  (6, 582), -- A cappella  ->  Contemporary A Cappella
  (6, 1054), -- A cappella  ->  Ghost Dance Song
  (6, 1275), -- A cappella  ->  Isicathamiya
  (6, 1581), -- A cappella  ->  Mbube
  (6, 2259), -- A cappella  ->  Sean-nós
  (6, 2291), -- A cappella  ->  Shape Note Singing
  (10, 11), -- Aboio  ->  Aboio cantado
  (13, 14), -- Acholi Music  ->  Acholitronix
  (24, 25), -- Acoustic Blues  ->  Acoustic Chicago Blues
  (24, 27), -- Acoustic Blues  ->  Acoustic Texas Blues
  (24, 1343), -- Acoustic Blues  ->  Jug Band
  (24, 1956), -- Acoustic Blues  ->  Piedmont Blues
  (33, 80), -- African Folk Music  ->  Ambasse bey
  (33, 111), -- African Folk Music  ->  Apala
  (33, 236), -- African Folk Music  ->  Batuque
  (33, 661), -- African Folk Music  ->  Dagomba Music
  (33, 1065), -- African Folk Music  ->  Gnawa
  (33, 1356), -- African Folk Music  ->  Kabye Folk Music
  (33, 1401), -- African Folk Music  ->  Kilapanga
  (33, 1523), -- African Folk Music  ->  Malagasy Folk Music
  (33, 1579), -- African Folk Music  ->  Mbenga-Mbuti Music
  (33, 1674), -- African Folk Music  ->  Moutya
  (33, 1793), -- African Folk Music  ->  Ngoma
  (33, 2389), -- African Folk Music  ->  Southern African Folk Music
  (33, 2507), -- African Folk Music  ->  Tchinkoumé
  (33, 2585), -- African Folk Music  ->  Traditional Maloya
  (33, 2588), -- African Folk Music  ->  Traditional Séga
  (33, 2810), -- African Folk Music  ->  Zinli
  (34, 33), -- African Music  ->  African Folk Music
  (34, 40), -- African Music  ->  Afro-Jazz
  (34, 438), -- African Music  ->  Cape Verdean Music
  (34, 464), -- African Music  ->  Central African Music
  (34, 801), -- African Music  ->  East African Music
  (34, 1524), -- African Music  ->  Malagasy Music
  (34, 1821), -- African Music  ->  North African Music
  (34, 1823), -- African Music  ->  Northeastern African Music
  (34, 2284), -- African Music  ->  Seychelles & Mascarene Islands Music
  (34, 2390), -- African Music  ->  Southern African Music
  (34, 2742), -- African Music  ->  West African Music
  (36, 5), -- Afro House  ->  3-Step
  (43, 45), -- Afrobeats  ->  Afropiano
  (43, 76), -- Afrobeats  ->  Alté
  (52, 2671), -- Ainu Music  ->  Upopo
  (52, 2791), -- Ainu Music  ->  Yukar
  (54, 1390), -- Akan Music  ->  Kete
  (54, 2812), -- Akan Music  ->  Zoblazo
  (59, 1446), -- Albanian Folk Music  ->  Lab Polyphony
  (59, 1690), -- Albanian Folk Music  ->  Musika popullore
  (59, 2569), -- Albanian Folk Music  ->  Tosk Polyphony
  (66, 424), -- Alpine Folk Music  ->  Canto degli Alpini
  (66, 1508), -- Alpine Folk Music  ->  Ländler
  (66, 1719), -- Alpine Folk Music  ->  Narodno zabavna glasba
  (66, 1724), -- Alpine Folk Music  ->  Naturjodel
  (68, 1079), -- Alt-Country  ->  Gothic Country
  (71, 1085), -- Alternative Dance  ->  Grebo
  (71, 1780), -- Alternative Dance  ->  New Rave
  (73, 989), -- Alternative Metal  ->  Funk Metal
  (73, 1756), -- Alternative Metal  ->  Neue Deutsche Härte
  (73, 1842), -- Alternative Metal  ->  Nu Metal
  (73, 2106), -- Alternative Metal  ->  Rap Metal
  (75, 71), -- Alternative Rock  ->  Alternative Dance
  (75, 360), -- Alternative Rock  ->  Britpop
  (75, 765), -- Alternative Rock  ->  Dream Pop
  (75, 841), -- Alternative Rock  ->  Emo-Pop
  (75, 1044), -- Alternative Rock  ->  Geek Rock
  (75, 1096), -- Alternative Rock  ->  Grunge
  (75, 1241), -- Alternative Rock  ->  Indie Rock
  (75, 1298), -- Alternative Rock  ->  Jangle Pop
  (75, 1532), -- Alternative Rock  ->  Mall Screamo
  (75, 2013), -- Alternative Rock  ->  Post-Britpop
  (75, 2015), -- Alternative Rock  ->  Post-Grunge
  (75, 2300), -- Alternative Rock  ->  Shimokita-kei
  (75, 2302), -- Alternative Rock  ->  Shoegaze
  (78, 45), -- Amapiano  ->  Afropiano
  (79, 51), -- Amazigh Music  ->  Ahwash
  (79, 1285), -- Amazigh Music  ->  Izlan
  (79, 1357), -- Amazigh Music  ->  Kabyle Music
  (79, 2202), -- Amazigh Music  ->  Sahrawi Music
  (79, 2426), -- Amazigh Music  ->  Staïfi
  (79, 2625), -- Amazigh Music  ->  Tuareg Music
  (81, 82), -- Ambient  ->  Ambient Americana
  (81, 677), -- Ambient  ->  Dark Ambient
  (81, 2400), -- Ambient  ->  Space Ambient
  (81, 2606), -- Ambient  ->  Tribal Ambient
  (91, 112), -- American Folk Music  ->  Appalachian Folk Music
  (91, 599), -- American Folk Music  ->  Country Blues
  (91, 894), -- American Folk Music  ->  Field Hollers
  (91, 897), -- American Folk Music  ->  Fife and Drum Blues
  (91, 1343), -- American Folk Music  ->  Jug Band
  (91, 1936), -- American Folk Music  ->  Pennsylvania Dutch Folk Music
  (91, 2143), -- American Folk Music  ->  Ring Shout
  (91, 2291), -- American Folk Music  ->  Shape Note Singing
  (91, 2415), -- American Folk Music  ->  Spiritual
  (91, 2484), -- American Folk Music  ->  Talking Blues
  (91, 2581), -- American Folk Music  ->  Traditional Cajun Music
  (91, 2582), -- American Folk Music  ->  Traditional Country
  (102, 98), -- Ancient Music  ->  Ancient Chinese Music
  (102, 99), -- Ancient Music  ->  Ancient Egyptian Music
  (102, 100), -- Ancient Music  ->  Ancient Greek Music
  (102, 101), -- Ancient Music  ->  Ancient Levitical Music
  (102, 103), -- Ancient Music  ->  Ancient Roman Music
  (102, 1214), -- Ancient Music  ->  Hyang-ak
  (102, 1607), -- Ancient Music  ->  Mesopotamian Music
  (105, 2201), -- Andalusian Folk Music  ->  Saeta
  (105, 2282), -- Andalusian Folk Music  ->  Sevillanas
  (108, 280), -- Animal Sounds  ->  Bird Sounds
  (108, 1264), -- Animal Sounds  ->  Insect Sounds
  (108, 2753), -- Animal Sounds  ->  Whale Song
  (112, 1875), -- Appalachian Folk Music  ->  Old-Time
  (116, 2110), -- Arabic Bellydance Music  ->  Raqs baladi
  (117, 104), -- Arabic Classical Music  ->  Andalusian Classical Music
  (117, 1272), -- Arabic Classical Music  ->  Iraqi Maqam
  (117, 2243), -- Arabic Classical Music  ->  Sawt
  (118, 53), -- Arabic Folk Music  ->  Aita
  (118, 116), -- Arabic Folk Music  ->  Arabic Bellydance Music
  (118, 170), -- Arabic Folk Music  ->  Ayyalah
  (118, 900), -- Arabic Folk Music  ->  Fijiri
  (118, 1488), -- Arabic Folk Music  ->  Liwa
  (118, 1846), -- Arabic Folk Music  ->  Nuban
  (118, 2198), -- Arabic Folk Music  ->  Sa'idi
  (120, 58), -- Arabic Music  ->  Al-Jadīd
  (120, 62), -- Arabic Music  ->  Algerian Chaabi
  (120, 117), -- Arabic Music  ->  Arabic Classical Music
  (120, 118), -- Arabic Music  ->  Arabic Folk Music
  (120, 119), -- Arabic Music  ->  Arabic Jazz
  (120, 121), -- Arabic Music  ->  Arabic Pop
  (120, 251), -- Arabic Music  ->  Bedouin Music
  (120, 659), -- Arabic Music  ->  Dabke
  (120, 1393), -- Arabic Music  ->  Khaliji Music
  (120, 1473), -- Arabic Music  ->  Levantine Arabic Music
  (120, 1895), -- Arabic Music  ->  Orkes gambus
  (120, 2120), -- Arabic Music  ->  Raï
  (120, 2285), -- Arabic Music  ->  Shaabi
  (120, 2793), -- Arabic Music  ->  Zajal
  (121, 57), -- Arabic Pop  ->  Al jeel
  (121, 1713), -- Arabic Pop  ->  Mūsīqā lubnāniyya
  (123, 626), -- Argentine Music  ->  Cuarteto
  (123, 635), -- Argentine Music  ->  Cumbia argentina
  (123, 1103), -- Argentine Music  ->  Guaracha santiagueña
  (123, 1857), -- Argentine Music  ->  Nuevo Cancionero
  (123, 2150), -- Argentine Music  ->  RKT
  (125, 1387), -- Armenian Folk Music  ->  Kef Music
  (126, 124), -- Armenian Music  ->  Armenian Church Music
  (126, 125), -- Armenian Music  ->  Armenian Folk Music
  (126, 2090), -- Armenian Music  ->  Rabiz
  (128, 131), -- Arrocha  ->  Arrochadeira
  (128, 344), -- Arrocha  ->  Bregadeira
  (136, 815), -- Art Punk  ->  Egg Punk
  (138, 836), -- Art Song  ->  Elizabethan Song
  (138, 1476), -- Art Song  ->  Lied
  (138, 1700), -- Art Song  ->  Mélodie
  (138, 1890), -- Art Song  ->  Orchestral Song
  (138, 2416), -- Art Song  ->  Spiritual Art Song
  (141, 140), -- Ashkenazi Music  ->  Ashkenazi Cantorial Music
  (141, 1408), -- Ashkenazi Music  ->  Klezmer
  (141, 2783), -- Ashkenazi Music  ->  Yiddish Folksong
  (142, 380), -- Asian Music  ->  Buddhist Music
  (142, 466), -- Asian Music  ->  Central Asian Music
  (142, 804), -- Asian Music  ->  East Asian Music
  (142, 1050), -- Asian Music  ->  Ghazal
  (142, 1822), -- Asian Music  ->  North Asian Music
  (142, 2383), -- Asian Music  ->  South Asian Music
  (142, 2387), -- Asian Music  ->  Southeast Asian Music
  (142, 2744), -- Asian Music  ->  West Asian Music
  (152, 294), -- Atmospheric Black Metal  ->  Blackgaze
  (158, 191), -- Austronesian Music  ->  Balinese Music
  (158, 229), -- Austronesian Music  ->  Batak Music
  (158, 1231), -- Austronesian Music  ->  Igorot Music
  (158, 1250), -- Austronesian Music  ->  Indigenous Taiwanese Music
  (158, 1306), -- Austronesian Music  ->  Javanese Music
  (158, 1524), -- Austronesian Music  ->  Malagasy Music
  (158, 1529), -- Austronesian Music  ->  Malay Music
  (158, 1629), -- Austronesian Music  ->  Minangkabau Music
  (158, 1915), -- Austronesian Music  ->  Pakacaping Music
  (158, 2444), -- Austronesian Music  ->  Sundanese Music
  (162, 950), -- Avant-Folk  ->  Free Folk
  (163, 874), -- Avant-Garde Jazz  ->  Experimental Big Band
  (163, 951), -- Avant-Garde Jazz  ->  Free Funk
  (163, 953), -- Avant-Garde Jazz  ->  Free Jazz
  (163, 2780), -- Avant-Garde Jazz  ->  Yass
  (165, 373), -- Avant-Prog  ->  Brutal Prog
  (165, 2804), -- Avant-Prog  ->  Zeuhl
  (168, 219), -- Avtorskaya pesnya  ->  Bard Rock
  (169, 1913), -- Axé  ->  Pagodão
  (169, 2224), -- Axé  ->  Samba-reggae
  (172, 171), -- Azerbaijani Music  ->  Azerbaijani Mugham
  (172, 1312), -- Azerbaijani Music  ->  Jazz Mugham
  (172, 1612), -- Azerbaijani Music  ->  Meyxana
  (172, 2464), -- Azerbaijani Music  ->  Symphonic Mugham
  (178, 382), -- Baganda Music  ->  Buganda Royal Court Music
  (178, 1359), -- Baganda Music  ->  Kadongo kamu
  (178, 1569), -- Baganda Music  ->  Mataali
  (190, 1024), -- Balinese Gamelan  ->  Gamelan angklung
  (190, 1027), -- Balinese Gamelan  ->  Gamelan gender wayang
  (190, 1028), -- Balinese Gamelan  ->  Gamelan gong gede
  (190, 1029), -- Balinese Gamelan  ->  Gamelan gong kebyar
  (190, 1030), -- Balinese Gamelan  ->  Gamelan jegog
  (190, 1033), -- Balinese Gamelan  ->  Gamelan semar pegulingan
  (191, 190), -- Balinese Music  ->  Balinese Gamelan
  (191, 1386), -- Balinese Music  ->  Kecak
  (194, 59), -- Balkan Folk Music  ->  Albanian Folk Music
  (194, 127), -- Balkan Folk Music  ->  Aromanian Folk Music
  (194, 193), -- Balkan Folk Music  ->  Balkan Brass Band
  (194, 320), -- Balkan Folk Music  ->  Bosnian Folk Music
  (194, 386), -- Balkan Folk Music  ->  Bulgarian Folk Music
  (194, 617), -- Balkan Folk Music  ->  Croatian Folk Music
  (194, 624), -- Balkan Folk Music  ->  Csango Folk Music
  (194, 1016), -- Balkan Folk Music  ->  Gagauz Folk Music
  (194, 1034), -- Balkan Folk Music  ->  Ganga
  (194, 1086), -- Balkan Folk Music  ->  Greek Folk Music
  (194, 1466), -- Balkan Folk Music  ->  Latvian Folk Music
  (194, 1509), -- Balkan Folk Music  ->  Macedonian Folk Music
  (194, 1657), -- Balkan Folk Music  ->  Montenegrin Folk Music
  (194, 1695), -- Balkan Folk Music  ->  Muzică lăutărească
  (194, 2271), -- Balkan Folk Music  ->  Serbian Folk Music
  (194, 2425), -- Balkan Folk Music  ->  Starogradska muzika
  (195, 194), -- Balkan Music  ->  Balkan Folk Music
  (195, 196), -- Balkan Music  ->  Balkan Pop-Folk
  (195, 848), -- Balkan Music  ->  Entechna
  (195, 1449), -- Balkan Music  ->  Laika
  (195, 2182), -- Balkan Music  ->  Romanţe
  (195, 2789), -- Balkan Music  ->  Yu-Mex
  (196, 470), -- Balkan Pop-Folk  ->  Chalga
  (196, 1543), -- Balkan Pop-Folk  ->  Manele
  (196, 1649), -- Balkan Pop-Folk  ->  Modern Laika
  (196, 1690), -- Balkan Pop-Folk  ->  Musika popullore
  (196, 1694), -- Balkan Pop-Folk  ->  Muzică de mahala
  (196, 2329), -- Balkan Pop-Folk  ->  Skiladika
  (196, 2485), -- Balkan Pop-Folk  ->  Tallava
  (196, 2630), -- Balkan Pop-Folk  ->  Turbo-Folk
  (198, 199), -- Ballet  ->  Ballet de cour
  (198, 570), -- Ballet  ->  Comédie-ballet
  (198, 1886), -- Ballet  ->  Opéra-ballet
  (202, 1484), -- Baltic Folk Music  ->  Lithuanian Folk Music
  (204, 854), -- Balto-Finnic Folk Music  ->  Estonian Folk Music
  (204, 906), -- Balto-Finnic Folk Music  ->  Finnish Folk Music
  (204, 1379), -- Balto-Finnic Folk Music  ->  Karelian Folk Music
  (204, 1487), -- Balto-Finnic Folk Music  ->  Livonian Folk Music
  (204, 2189), -- Balto-Finnic Folk Music  ->  Rune Singing
  (206, 205), -- Bamar Music  ->  Bamar Folk Music
  (206, 389), -- Bamar Music  ->  Burmese Classical Music
  (206, 1655), -- Bamar Music  ->  Mono
  (210, 1676), -- Banda sinaloense  ->  Movimiento Alterado
  (210, 2520), -- Banda sinaloense  ->  Tecnobanda
  (212, 210), -- Bandas de viento de México  ->  Banda sinaloense
  (218, 1342), -- Barbershop  ->  Jubilee
  (221, 199), -- Baroque Music  ->  Ballet de cour
  (221, 570), -- Baroque Music  ->  Comédie-ballet
  (221, 1886), -- Baroque Music  ->  Opéra-ballet
  (221, 2798), -- Baroque Music  ->  Zarzuela barroca
  (226, 2844), -- Basque Folk Music  ->  Trikitixa
  (227, 2412), -- Bass House  ->  Speed House
  (229, 1071), -- Batak Music  ->  Gondang
  (229, 1991), -- Batak Music  ->  Pop Batak
  (242, 948), -- Beat  ->  Freakbeat
  (242, 1095), -- Beat  ->  Group Sounds
  (242, 1341), -- Beat  ->  Jovem Guarda
  (242, 1605), -- Beat  ->  Merseybeat
  (251, 53), -- Bedouin Music  ->  Aita
  (251, 170), -- Bedouin Music  ->  Ayyalah
  (251, 2231), -- Bedouin Music  ->  Samri
  (251, 2298), -- Bedouin Music  ->  Shilla
  (261, 237), -- Bengali Folk Music  ->  Baul gaan
  (269, 926), -- Bhangra  ->  Folkhop
  (270, 279), -- Bhojpuri Folk Music  ->  Biraha
  (271, 874), -- Big Band  ->  Experimental Big Band
  (271, 2039), -- Big Band  ->  Progressive Big Band
  (282, 521), -- Bit Music  ->  Chiptune
  (282, 919), -- Bit Music  ->  FM Synthesis
  (282, 1620), -- Bit Music  ->  MIDI Music
  (282, 2270), -- Bit Music  ->  Sequencer & Tracker
  (287, 2032), -- Black Gospel  ->  Praise Break
  (287, 2200), -- Black Gospel  ->  Sacred Steel
  (287, 2579), -- Black Gospel  ->  Traditional Black Gospel
  (287, 2673), -- Black Gospel  ->  Urban Contemporary Gospel
  (288, 152), -- Black Metal  ->  Atmospheric Black Metal
  (288, 285), -- Black Metal  ->  Black 'n' Roll
  (288, 290), -- Black Metal  ->  Black Noise
  (288, 293), -- Black Metal  ->  Blackened Death Metal
  (288, 740), -- Black Metal  ->  Dissonant Black Metal
  (288, 782), -- Black Metal  ->  DSBM
  (288, 1170), -- Black Metal  ->  Hellenic Black Metal
  (288, 1591), -- Black Metal  ->  Melodic Black Metal
  (288, 1909), -- Black Metal  ->  Pagan Black Metal
  (288, 2011), -- Black Metal  ->  Post-Black Metal
  (288, 2462), -- Black Metal  ->  Symphonic Black Metal
  (288, 2734), -- Black Metal  ->  War Metal
  (298, 2040), -- Bluegrass  ->  Progressive Bluegrass
  (298, 2580), -- Bluegrass  ->  Traditional Bluegrass
  (300, 24), -- Blues  ->  Acoustic Blues
  (300, 317), -- Blues  ->  Boogie Woogie
  (300, 599), -- Blues  ->  Country Blues
  (300, 817), -- Blues  ->  Electric Blues
  (300, 897), -- Blues  ->  Fife and Drum Blues
  (300, 1345), -- Blues  ->  Jump Blues
  (300, 1953), -- Blues  ->  Piano Blues
  (300, 2372), -- Blues  ->  Soul Blues
  (300, 2698), -- Blues  ->  Vaudeville Blues
  (301, 316), -- Blues Rock  ->  Boogie Rock
  (306, 308), -- Bolero  ->  Bolero son
  (306, 901), -- Bolero  ->  Filin
  (320, 1286), -- Bosnian Folk Music  ->  Izvorna bosanska muzika
  (320, 2281), -- Bosnian Folk Music  ->  Sevdalinka
  (324, 2320), -- Bounce  ->  Sissy Bounce
  (330, 1586), -- Brazilian Bass  ->  Mega funk
  (330, 2337), -- Brazilian Bass  ->  Slap House
  (331, 2690), -- Brazilian Classical Music  ->  Valsa brasileira
  (332, 10), -- Brazilian Folk Music  ->  Aboio
  (332, 208), -- Brazilian Folk Music  ->  Banda de pífano
  (332, 417), -- Brazilian Folk Music  ->  Candomblé Music
  (332, 428), -- Brazilian Folk Music  ->  Cantoria
  (332, 439), -- Brazilian Folk Music  ->  Capoeira Music
  (332, 652), -- Brazilian Folk Music  ->  Cururu
  (332, 885), -- Brazilian Folk Music  ->  Fandango caiçara
  (332, 1338), -- Brazilian Folk Music  ->  Jongo
  (332, 1505), -- Brazilian Folk Music  ->  Lundu
  (332, 1555), -- Brazilian Folk Music  ->  Maracatu
  (332, 1650), -- Brazilian Folk Music  ->  Modinha
  (332, 2114), -- Brazilian Folk Music  ->  Rasqueado
  (332, 2214), -- Brazilian Folk Music  ->  Samba de roda
  (332, 2277), -- Brazilian Folk Music  ->  Sertanejo de raiz
  (332, 2560), -- Brazilian Folk Music  ->  Toada de Boi
  (332, 2767), -- Brazilian Folk Music  ->  Xaxado
  (333, 331), -- Brazilian Music  ->  Brazilian Classical Music
  (333, 332), -- Brazilian Music  ->  Brazilian Folk Music
  (333, 341), -- Brazilian Music  ->  Brega
  (333, 749), -- Brazilian Music  ->  Dobrado
  (333, 983), -- Brazilian Music  ->  Funk brasileiro
  (333, 1450), -- Brazilian Music  ->  Lambada
  (333, 1678), -- Brazilian Music  ->  MPB
  (333, 1824), -- Brazilian Music  ->  Northeastern Brazilian Music
  (333, 1826), -- Brazilian Music  ->  Northern Brazilian Music
  (333, 2163), -- Brazilian Music  ->  Rock rural
  (333, 2211), -- Brazilian Music  ->  Samba
  (333, 2216), -- Brazilian Music  ->  Samba Rap
  (333, 2276), -- Brazilian Music  ->  Sertanejo
  (333, 2388), -- Brazilian Music  ->  Southeastern Brazilian Music
  (333, 2391), -- Brazilian Music  ->  Southern Brazilian Music
  (333, 2771), -- Brazilian Music  ->  Xote
  (336, 16), -- Breakbeat  ->  Acid Breaks
  (336, 203), -- Breakbeat  ->  Baltimore Club
  (336, 272), -- Breakbeat  ->  Big Beat
  (336, 337), -- Breakbeat  ->  Breakbeat Hardcore
  (336, 338), -- Breakbeat  ->  Breakbeat Kota
  (336, 917), -- Breakbeat  ->  Florida Breaks
  (336, 996), -- Breakbeat  ->  Funky Breaks
  (336, 1843), -- Breakbeat  ->  Nu Skool Breaks
  (336, 2041), -- Breakbeat  ->  Progressive Breaks
  (336, 2055), -- Breakbeat  ->  Psybreaks
  (336, 2745), -- Breakbeat  ->  West Coast Breaks
  (337, 687), -- Breakbeat Hardcore  ->  Darkside
  (337, 1146), -- Breakbeat Hardcore  ->  Hardcore Breaks
  (337, 2828), -- Breakbeat Hardcore  ->  Toytown Techno
  (337, 2830), -- Breakbeat Hardcore  ->  Jungle Techno
  (338, 1349), -- Breakbeat Kota  ->  Jungle Dutch
  (339, 1493), -- Breakcore  ->  Lolicore
  (339, 1565), -- Breakcore  ->  Mashcore
  (339, 2099), -- Breakcore  ->  Raggacore
  (341, 128), -- Brega  ->  Arrocha
  (341, 342), -- Brega  ->  Brega calypso
  (341, 2521), -- Brega  ->  Tecnobrega
  (343, 231), -- Brega funk  ->  Batidão romântico
  (345, 177), -- Breton Celtic Folk Music  ->  Bagad
  (346, 345), -- Breton Folk Music  ->  Breton Celtic Folk Music
  (346, 1369), -- Breton Folk Music  ->  Kan ha diskan
  (352, 2836), -- British Beat Boom  ->  Brumbeat
  (357, 197), -- British Music  ->  Ballad Opera
  (357, 354), -- British Music  ->  British Brass Band
  (357, 355), -- British Music  ->  British Dance Band
  (357, 356), -- British Music  ->  British Folk Rock
  (357, 481), -- British Music  ->  Change Ringing
  (357, 573), -- British Music  ->  Concertina Band
  (357, 586), -- British Music  ->  Contenance angloise
  (357, 844), -- British Music  ->  English Folk Music
  (357, 845), -- British Music  ->  English Pastoral School
  (357, 1686), -- British Music  ->  Music Hall
  (357, 2240), -- British Music  ->  Sarum Chant
  (357, 2252), -- British Music  ->  Scottish Folk Music
  (357, 2741), -- British Music  ->  Welsh Folk Music
  (370, 347), -- Brostep  ->  Briddim
  (370, 562), -- Brostep  ->  Colour Bass
  (370, 701), -- Brostep  ->  Deathstep
  (370, 780), -- Brostep  ->  Drumstep
  (370, 2509), -- Brostep  ->  Tearout [Brostep]
  (372, 2335), -- Brutal Death Metal  ->  Slam Death Metal
  (380, 265), -- Buddhist Music  ->  Beompae
  (380, 540), -- Buddhist Music  ->  Chöd
  (380, 2307), -- Buddhist Music  ->  Shōmyō
  (380, 2550), -- Buddhist Music  ->  Tibetan Buddhist Chant
  (395, 394), -- Byzantine Music  ->  Byzantine Chant
  (397, 427), -- C-Pop  ->  Cantopop
  (397, 1105), -- C-Pop  ->  Gufeng
  (397, 1194), -- C-Pop  ->  Hokkien Pop
  (397, 1542), -- C-Pop  ->  Mandopop
  (397, 2807), -- C-Pop  ->  Zhongguo feng
  (404, 2581), -- Cajun Music  ->  Traditional Cajun Music
  (407, 406), -- Calypso  ->  Calipso venezolano
  (407, 2421), -- Calypso  ->  Spouge
  (408, 2171), -- Cambodian Pop  ->  Rom kbach
  (411, 412), -- Canadian Folk Music  ->  Canadian Maritime Folk
  (411, 964), -- Canadian Folk Music  ->  French-Canadian Folk Music
  (411, 1702), -- Canadian Folk Music  ->  Métis Fiddling
  (411, 1792), -- Canadian Folk Music  ->  Newfoundland Folk Music
  (412, 436), -- Canadian Maritime Folk  ->  Cape Breton Folk Music
  (414, 310), -- Canción melódica  ->  Bolero-Beat
  (414, 1704), -- Canción melódica  ->  Música cebolla
  (420, 1733), -- Canterbury Scene  ->  Neo-Canterbury
  (428, 2133), -- Cantoria  ->  Repente
  (436, 435), -- Cape Breton Folk Music  ->  Cape Breton Fiddling
  (438, 236), -- Cape Verdean Music  ->  Batuque
  (438, 559), -- Cape Verdean Music  ->  Coladeira
  (438, 976), -- Cape Verdean Music  ->  Funaná
  (438, 1666), -- Cape Verdean Music  ->  Morna
  (443, 256), -- Caribbean Folk Music  ->  Bele
  (443, 263), -- Caribbean Folk Music  ->  Benna
  (443, 312), -- Caribbean Folk Music  ->  Bomba
  (443, 979), -- Caribbean Folk Music  ->  Fungi
  (443, 1120), -- Caribbean Folk Music  ->  Haitian Vodou Drumming
  (443, 1331), -- Caribbean Folk Music  ->  Jibaro
  (443, 1363), -- Caribbean Folk Music  ->  Kaiso
  (443, 1403), -- Caribbean Folk Music  ->  Kitchen Dance Music
  (443, 1432), -- Caribbean Folk Music  ->  Kumina
  (443, 1600), -- Caribbean Folk Music  ->  Mento
  (443, 1701), -- Caribbean Folk Music  ->  Méringue
  (443, 1970), -- Caribbean Folk Music  ->  Plena
  (443, 2146), -- Caribbean Folk Music  ->  Ripsaw
  (443, 2609), -- Caribbean Folk Music  ->  Trinidadian Cariso
  (443, 2626), -- Caribbean Folk Music  ->  Tumba
  (443, 2713), -- Caribbean Folk Music  ->  Virgin Islander Cariso
  (444, 60), -- Caribbean Music  ->  Aleke
  (444, 371), -- Caribbean Music  ->  Brukdown
  (444, 387), -- Caribbean Music  ->  Bullerengue
  (444, 407), -- Caribbean Music  ->  Calypso
  (444, 443), -- Caribbean Music  ->  Caribbean Folk Music
  (444, 479), -- Caribbean Music  ->  Champeta
  (444, 628), -- Caribbean Music  ->  Cuban Music
  (444, 637), -- Caribbean Music  ->  Cumbia colombiana
  (444, 752), -- Caribbean Music  ->  Dominican Music
  (444, 958), -- Caribbean Music  ->  French Caribbean Music
  (444, 1018), -- Caribbean Music  ->  Gaita zuliana
  (444, 1042), -- Caribbean Music  ->  Garifuna Folk Music
  (444, 1072), -- Caribbean Music  ->  Goombay
  (444, 1252), -- Caribbean Music  ->  Indo-Caribbean Music
  (444, 1294), -- Caribbean Music  ->  Jamaican Music
  (444, 1351), -- Caribbean Music  ->  Junkanoo
  (444, 1380), -- Caribbean Music  ->  Kaseko
  (444, 1919), -- Caribbean Music  ->  Palo de mayo
  (444, 1926), -- Caribbean Music  ->  Parang
  (444, 2006), -- Caribbean Music  ->  Porro
  (444, 2350), -- Caribbean Music  ->  Soca
  (444, 2427), -- Caribbean Music  ->  Steel Band
  (444, 2613), -- Caribbean Music  ->  Tropicanibalismo
  (444, 2687), -- Caribbean Music  ->  Vallenato
  (446, 1412), -- Carnatic Classical Music  ->  Konnakol
  (453, 2238), -- Catalan Folk Music  ->  Sardana
  (454, 9), -- Caucasian Folk Music  ->  Abkhazian Folk Music
  (454, 493), -- Caucasian Folk Music  ->  Chechen Folk Music
  (454, 544), -- Caucasian Folk Music  ->  Circassian Folk Music
  (454, 660), -- Caucasian Folk Music  ->  Dagestani Folk Music
  (454, 1047), -- Caucasian Folk Music  ->  Georgian Folk Music
  (454, 1898), -- Caucasian Folk Music  ->  Ossetian Folk Music
  (455, 454), -- Caucasian Music  ->  Caucasian Folk Music
  (455, 1377), -- Caucasian Music  ->  Karachay-Balkarian Music
  (455, 2090), -- Caucasian Music  ->  Rabiz
  (456, 1327), -- CCM  ->  Jesus Music
  (456, 2031), -- CCM  ->  Praise & Worship
  (456, 2673), -- CCM  ->  Urban Contemporary Gospel
  (459, 345), -- Celtic Folk Music  ->  Breton Celtic Folk Music
  (459, 436), -- Celtic Folk Music  ->  Cape Breton Folk Music
  (459, 592), -- Celtic Folk Music  ->  Cornish Folk Music
  (459, 1273), -- Celtic Folk Music  ->  Irish Folk Music
  (459, 1548), -- Celtic Folk Music  ->  Manx Folk Music
  (459, 2252), -- Celtic Folk Music  ->  Scottish Folk Music
  (459, 2741), -- Celtic Folk Music  ->  Welsh Folk Music
  (464, 80), -- Central African Music  ->  Ambasse bey
  (464, 147), -- Central African Music  ->  Assiko
  (464, 209), -- Central African Music  ->  Banda Music
  (464, 259), -- Central African Music  ->  Bend-skin
  (464, 277), -- Central African Music  ->  Bikutsi
  (464, 579), -- Central African Music  ->  Congolese Rumba
  (464, 1366), -- Central African Music  ->  Kalindula
  (464, 1401), -- Central African Music  ->  Kilapanga
  (464, 1404), -- Central African Music  ->  Kizomba
  (464, 1428), -- Central African Music  ->  Kuduro
  (464, 1522), -- Central African Music  ->  Makossa
  (464, 1544), -- Central African Music  ->  Mangambeu
  (464, 1579), -- Central African Music  ->  Mbenga-Mbuti Music
  (464, 1580), -- Central African Music  ->  Mbolé
  (464, 2077), -- Central African Music  ->  Puxa
  (464, 2267), -- Central African Music  ->  Semba
  (464, 2370), -- Central African Music  ->  Soukous
  (464, 2577), -- Central African Music  ->  Tradi-moderne congolais
  (464, 2643), -- Central African Music  ->  Twa Music
  (464, 2796), -- Central African Music  ->  Zamrock
  (465, 371), -- Central American Music  ->  Brukdown
  (465, 644), -- Central American Music  ->  Cumbia salvadoreña
  (465, 1042), -- Central American Music  ->  Garifuna Folk Music
  (465, 1919), -- Central American Music  ->  Palo de mayo
  (465, 2076), -- Central American Music  ->  Purísima
  (465, 2358), -- Central American Music  ->  Son de pascua
  (465, 2363), -- Central American Music  ->  Son nica
  (465, 2486), -- Central American Music  ->  Tamborera
  (465, 2487), -- Central American Music  ->  Tamborito
  (465, 2773), -- Central American Music  ->  Xuc
  (466, 70), -- Central Asian Music  ->  Altai Music
  (466, 201), -- Central Asian Music  ->  Balochi Music
  (466, 224), -- Central Asian Music  ->  Bashkir Folk Music
  (466, 392), -- Central Asian Music  ->  Burushaski Folk Music
  (466, 467), -- Central Asian Music  ->  Central Asian Throat Singing
  (466, 1164), -- Central Asian Music  ->  Hazara Folk Music
  (466, 1378), -- Central Asian Music  ->  Karakalpak Traditional Music
  (466, 1385), -- Central Asian Music  ->  Kazakh Music
  (466, 1392), -- Central Asian Music  ->  Khakas Traditional Music
  (466, 1442), -- Central Asian Music  ->  Kyrgyz Traditional Music
  (466, 1653), -- Central Asian Music  ->  Mongolian Music
  (466, 1920), -- Central Asian Music  ->  Pamiri Music
  (466, 1929), -- Central Asian Music  ->  Pashto Folk Music
  (466, 2292), -- Central Asian Music  ->  Shashmaqam
  (466, 2443), -- Central Asian Music  ->  Sufiana kalam
  (466, 2480), -- Central Asian Music  ->  Tajik Music
  (466, 2502), -- Central Asian Music  ->  Tarz
  (466, 2551), -- Central Asian Music  ->  Tibetan Music
  (466, 2638), -- Central Asian Music  ->  Turkmen Music
  (466, 2681), -- Central Asian Music  ->  Uyghur Music
  (466, 2682), -- Central Asian Music  ->  Uzbek Music
  (467, 1362), -- Central Asian Throat Singing  ->  Kai
  (467, 1654), -- Central Asian Throat Singing  ->  Mongolian Throat Singing
  (467, 2642), -- Central Asian Throat Singing  ->  Tuvan Throat Singing
  (471, 472), -- Chamamé  ->  Chamamé tropical
  (477, 2439), -- Chamber Music  ->  String Quartet
  (484, 485), -- Chanson  ->  Chanson alternative
  (484, 486), -- Chanson  ->  Chanson québécoise
  (484, 487), -- Chanson  ->  Chanson réaliste
  (484, 488), -- Chanson  ->  Chanson à texte
  (484, 1832), -- Chanson  ->  Nouvelle chanson française
  (491, 1235), -- Character Piece  ->  Impromptu
  (491, 1806), -- Character Piece  ->  Nocturne
  (492, 140), -- Chazzanut  ->  Ashkenazi Cantorial Music
  (495, 319), -- Chicago Drill  ->  Bop
  (496, 1445), -- Chicago Hard House  ->  LA Hard House
  (505, 1504), -- Children's Music  ->  Lullabies
  (505, 1858), -- Children's Music  ->  Nursery Rhymes
  (506, 421), -- Chilean Music  ->  Canto a lo poeta
  (506, 512), -- Chilean Music  ->  Chilote Music
  (506, 632), -- Chilean Music  ->  Cueca brava
  (506, 636), -- Chilean Music  ->  Cumbia chilena
  (506, 1310), -- Chilean Music  ->  Jazz guachaca
  (506, 1538), -- Chilean Music  ->  Mambo chileno
  (506, 1704), -- Chilean Music  ->  Música cebolla
  (506, 1710), -- Chilean Music  ->  Música típica chilena
  (506, 1850), -- Chilean Music  ->  Nueva canción chilena
  (506, 2563), -- Chilean Music  ->  Tonada chilena
  (508, 83), -- Chillout  ->  Ambient Dub
  (508, 84), -- Chillout  ->  Ambient House
  (508, 89), -- Chillout  ->  Ambient Trance
  (508, 189), -- Chillout  ->  Balearic Beat
  (508, 217), -- Chillout  ->  Barber Beats
  (508, 763), -- Chillout  ->  Downtempo
  (508, 2054), -- Chillout  ->  Psybient
  (511, 510), -- Chillwave  ->  Chillsynth
  (515, 184), -- Chinese Classical Music  ->  Baisha xiyue
  (515, 517), -- Chinese Classical Music  ->  Chinese Literati Music
  (515, 754), -- Chinese Classical Music  ->  Dongjing
  (515, 2778), -- Chinese Classical Music  ->  Yanyue
  (515, 2781), -- Chinese Classical Music  ->  Yayue
  (516, 489), -- Chinese Folk Music  ->  Chaozhou xianshi
  (516, 1125), -- Chinese Folk Music  ->  Han Folk Music
  (516, 1128), -- Chinese Folk Music  ->  Haozi
  (516, 1330), -- Chinese Folk Music  ->  Jiangnan sizhu
  (516, 2288), -- Chinese Folk Music  ->  Shan'ge
  (516, 2852), -- Chinese Folk Music  ->  Dongzu dage
  (518, 98), -- Chinese Music  ->  Ancient Chinese Music
  (518, 410), -- Chinese Music  ->  Campus Folk
  (518, 515), -- Chinese Music  ->  Chinese Classical Music
  (518, 516), -- Chinese Music  ->  Chinese Folk Music
  (518, 519), -- Chinese Music  ->  Chinese Opera
  (518, 1639), -- Chinese Music  ->  Minyue
  (518, 1726), -- Chinese Music  ->  Naxi Music
  (518, 2087), -- Chinese Music  ->  Quyi
  (518, 2297), -- Chinese Music  ->  Shidaiqu
  (518, 2322), -- Chinese Music  ->  Sizhu Music
  (518, 2494), -- Chinese Music  ->  Taoist Ritual Music
  (518, 2769), -- Chinese Music  ->  Xibei feng
  (518, 2770), -- Chinese Music  ->  Xinyao
  (518, 2807), -- Chinese Music  ->  Zhongguo feng
  (519, 426), -- Chinese Opera  ->  Cantonese Opera
  (519, 1171), -- Chinese Opera  ->  Henan Opera
  (519, 1435), -- Chinese Opera  ->  Kunqu Opera
  (519, 1935), -- Chinese Opera  ->  Peking Opera
  (519, 2290), -- Chinese Opera  ->  Shaoxing Opera
  (519, 2309), -- Chinese Opera  ->  Sichuan Opera
  (519, 2777), -- Chinese Opera  ->  Yangzhou Opera
  (524, 525), -- Choral  ->  Choral Concerto
  (524, 526), -- Choral  ->  Choral Symphony
  (527, 2219), -- Choro  ->  Samba-choro
  (531, 107), -- Christian Liturgical Music  ->  Anglican Chant
  (531, 124), -- Christian Liturgical Music  ->  Armenian Church Music
  (531, 394), -- Christian Liturgical Music  ->  Byzantine Chant
  (531, 591), -- Christian Liturgical Music  ->  Coptic Music
  (531, 807), -- Christian Liturgical Music  ->  East Slavic Church Music
  (531, 857), -- Christian Liturgical Music  ->  Ethiopian Church Music
  (531, 1568), -- Christian Liturgical Music  ->  Mass
  (531, 1932), -- Christian Liturgical Music  ->  Passion
  (531, 1969), -- Christian Liturgical Music  ->  Plainsong
  (531, 2265), -- Christian Liturgical Music  ->  Seinn nan salm
  (531, 2472), -- Christian Liturgical Music  ->  Syriac Chant
  (532, 2768), -- Christian Rock  ->  Xian Psych
  (533, 2358), -- Christmas Music  ->  Son de pascua
  (536, 537), -- Chutney  ->  Chutney Soca
  (542, 853), -- Cinematic Classical  ->  Epic Music
  (542, 2405), -- Cinematic Classical  ->  Spaghetti Western
  (546, 1734), -- City Pop  ->  Neo-City Pop
  (548, 2840), -- Classical Crossover  ->  Operatic Pop
  (550, 382), -- Classical Music  ->  Buganda Royal Court Music
  (550, 802), -- Classical Music  ->  East Asian Classical Music
  (550, 1263), -- Classical Music  ->  Inkiranya
  (550, 1390), -- Classical Music  ->  Kete
  (550, 1553), -- Classical Music  ->  Maqāmic Music
  (550, 1639), -- Classical Music  ->  Minyue
  (550, 2080), -- Classical Music  ->  Pìobaireachd
  (550, 2381), -- Classical Music  ->  South Asian Classical Music
  (550, 2385), -- Classical Music  ->  Southeast Asian Classical Music
  (550, 2550), -- Classical Music  ->  Tibetan Buddhist Chant
  (550, 2751), -- Classical Music  ->  Western Classical Music
  (557, 543), -- Coco  ->  Ciranda
  (557, 837), -- Coco  ->  Embolada
  (563, 335), -- Comedy  ->  Break-In
  (563, 795), -- Comedy  ->  Dutch Cabaret
  (563, 1355), -- Comedy  ->  Kabarett
  (563, 1687), -- Comedy  ->  Musical Comedy
  (563, 2033), -- Comedy  ->  Prank Call
  (563, 2327), -- Comedy  ->  Sketch Comedy
  (563, 2423), -- Comedy  ->  Stand-Up Comedy
  (564, 490), -- Comedy Rap  ->  Chap Hop
  (572, 1342), -- Concert Spiritual  ->  Jubilee
  (572, 2416), -- Concert Spiritual  ->  Spiritual Art Song
  (574, 575), -- Concerto  ->  Concerto for Orchestra
  (574, 576), -- Concerto  ->  Concerto grosso
  (574, 2315), -- Concerto  ->  Sinfonia concertante
  (583, 329), -- Contemporary Country  ->  Boyfriend Country
  (583, 362), -- Contemporary Country  ->  Bro-Country
  (583, 1741), -- Contemporary Country  ->  Neo-Traditionalist Country
  (584, 93), -- Contemporary Folk  ->  American Primitivism
  (584, 109), -- Contemporary Folk  ->  Anti-Folk
  (584, 162), -- Contemporary Folk  ->  Avant-Folk
  (584, 410), -- Contemporary Folk  ->  Campus Folk
  (584, 475), -- Contemporary Folk  ->  Chamber Folk
  (584, 601), -- Contemporary Folk  ->  Country Folk
  (584, 921), -- Contemporary Folk  ->  Folk Baroque
  (584, 923), -- Contemporary Folk  ->  Folk Pop
  (584, 1238), -- Contemporary Folk  ->  Indie Folk
  (584, 1494), -- Contemporary Folk  ->  Loner Folk
  (584, 1747), -- Contemporary Folk  ->  Neofolk
  (584, 1748), -- Contemporary Folk  ->  Neofolklore
  (584, 2044), -- Contemporary Folk  ->  Progressive Folk
  (584, 2057), -- Contemporary Folk  ->  Psychedelic Folk
  (584, 2328), -- Contemporary Folk  ->  Skiffle
  (584, 2770), -- Contemporary Folk  ->  Xinyao
  (585, 74), -- Contemporary R&B  ->  Alternative R&B
  (585, 1183), -- Contemporary R&B  ->  Hip Hop Soul
  (585, 1769), -- Contemporary R&B  ->  New Jack Swing
  (585, 2602), -- Contemporary R&B  ->  Trap Soul
  (585, 2661), -- Contemporary R&B  ->  UK Street Soul
  (595, 1910), -- Corsican Folk Music  ->  Paghjella
  (597, 68), -- Country  ->  Alt-Country
  (597, 94), -- Country  ->  Americana
  (597, 298), -- Country  ->  Bluegrass
  (597, 583), -- Country  ->  Contemporary Country
  (597, 598), -- Country  ->  Country & Irish
  (597, 600), -- Country  ->  Country Boogie
  (597, 601), -- Country  ->  Country Folk
  (597, 603), -- Country  ->  Country Pop
  (597, 1199), -- Country  ->  Honky Tonk
  (597, 1721), -- Country  ->  Nashville Sound
  (597, 2042), -- Country  ->  Progressive Country
  (597, 2582), -- Country  ->  Traditional Country
  (597, 2750), -- Country  ->  Western
  (597, 2752), -- Country  ->  Western Swing
  (599, 27), -- Country Blues  ->  Acoustic Texas Blues
  (599, 711), -- Country Blues  ->  Delta Blues
  (599, 1178), -- Country Blues  ->  Hill Country Blues
  (599, 1956), -- Country Blues  ->  Piedmont Blues
  (602, 299), -- Country Gospel  ->  Bluegrass Gospel
  (603, 329), -- Country Pop  ->  Boyfriend Country
  (603, 362), -- Country Pop  ->  Bro-Country
  (603, 608), -- Country Pop  ->  Countrypolitan
  (603, 2674), -- Country Pop  ->  Urban Cowboy
  (605, 596), -- Country Rock  ->  Cosmic Country
  (613, 2149), -- Cretan Folk Music  ->  Rizitika
  (617, 1405), -- Croatian Folk Music  ->  Klapa
  (623, 292), -- Crust Punk  ->  Blackened Crust
  (623, 1746), -- Crust Punk  ->  Neocrust
  (623, 2428), -- Crust Punk  ->  Stenchcore
  (628, 8), -- Cuban Music  ->  Abakuá Music
  (628, 469), -- Cuban Music  ->  Chachachá
  (628, 483), -- Cuban Music  ->  Changüí
  (628, 578), -- Cuban Music  ->  Conga
  (628, 627), -- Cuban Music  ->  Cuban Charanga
  (628, 629), -- Cuban Music  ->  Cubaton
  (628, 675), -- Cuban Music  ->  Danzón
  (628, 717), -- Cuban Music  ->  Descarga
  (628, 901), -- Cuban Music  ->  Filin
  (628, 1099), -- Cuban Music  ->  Guajira
  (628, 1101), -- Cuban Music  ->  Guaracha
  (628, 1117), -- Cuban Music  ->  Habanera
  (628, 1537), -- Cuban Music  ->  Mambo
  (628, 1677), -- Cuban Music  ->  Mozambique
  (628, 1907), -- Cuban Music  ->  Pachanga
  (628, 1958), -- Cuban Music  ->  Pilón
  (628, 2187), -- Cuban Music  ->  Rumba cubana
  (628, 2235), -- Cuban Music  ->  Santería Music
  (628, 2357), -- Cuban Music  ->  Son cubano
  (628, 2366), -- Cuban Music  ->  Songo
  (628, 2554), -- Cuban Music  ->  Timba
  (628, 2617), -- Cuban Music  ->  Trova
  (628, 2627), -- Cuban Music  ->  Tumba francesa
  (629, 2132), -- Cubaton  ->  Reparto
  (631, 632), -- Cueca  ->  Cueca brava
  (633, 635), -- Cumbia  ->  Cumbia argentina
  (633, 636), -- Cumbia  ->  Cumbia chilena
  (633, 637), -- Cumbia  ->  Cumbia colombiana
  (633, 638), -- Cumbia  ->  Cumbia mexicana
  (633, 641), -- Cumbia  ->  Cumbia peruana
  (633, 642), -- Cumbia  ->  Cumbia pop
  (633, 644), -- Cumbia  ->  Cumbia salvadoreña
  (633, 729), -- Cumbia  ->  Digital Cumbia
  (633, 1601), -- Cumbia  ->  Merecumbé
  (635, 645), -- Cumbia argentina  ->  Cumbia santafesina
  (635, 647), -- Cumbia argentina  ->  Cumbia turra
  (635, 648), -- Cumbia argentina  ->  Cumbia villera
  (636, 1853), -- Cumbia chilena  ->  Nueva cumbia chilena
  (638, 646), -- Cumbia mexicana  ->  Cumbia sonidera
  (641, 503), -- Cumbia peruana  ->  Chicha
  (641, 634), -- Cumbia peruana  ->  Cumbia amazónica
  (641, 640), -- Cumbia peruana  ->  Cumbia norteña peruana
  (641, 2855), -- Cumbia peruana  ->  Cumbia sureña peruana
  (646, 643), -- Cumbia sonidera  ->  Cumbia rebajada
  (658, 2135), -- D.C. Hardcore  ->  Revolution Summer
  (660, 167), -- Dagestani Folk Music  ->  Avar Folk Music
  (662, 71), -- Dance  ->  Alternative Dance
  (662, 663), -- Dance  ->  Dance-Pop
  (662, 737), -- Dance  ->  Disco
  (662, 830), -- Dance  ->  Electronic Dance Music
  (662, 1613), -- Dance  ->  Miami Bass
  (662, 2728), -- Dance  ->  Wa Euro
  (663, 376), -- Dance-Pop  ->  Bubblegum Dance
  (663, 738), -- Dance-Pop  ->  Disco polo
  (663, 956), -- Dance-Pop  ->  Freestyle
  (663, 988), -- Dance-Pop  ->  Funk Melody
  (663, 2178), -- Dance-Pop  ->  Romanian Popcorn
  (663, 2524), -- Dance-Pop  ->  Tecnorumba
  (663, 2572), -- Dance-Pop  ->  Township Bubblegum
  (664, 665), -- Dance-Punk  ->  Dance-Punk Revival
  (667, 377), -- Dancehall  ->  Bubbling
  (667, 730), -- Dancehall  ->  Digital Dancehall
  (667, 915), -- Dancehall  ->  Flex Dance Music
  (667, 1070), -- Dancehall  ->  Gommance
  (667, 2097), -- Dancehall  ->  Ragga
  (667, 2293), -- Dancehall  ->  Shatta
  (667, 2598), -- Dancehall  ->  Trap Dancehall
  (667, 2803), -- Dancehall  ->  Zess
  (669, 670), -- Dangdut  ->  Dangdut koplo
  (677, 286), -- Dark Ambient  ->  Black Ambient
  (677, 2148), -- Dark Ambient  ->  Ritual Ambient
  (680, 49), -- Dark Electro  ->  Aggrotech
  (685, 1175), -- Dark Psytrance  ->  Hi-Tech Psytrance
  (685, 2063), -- Dark Psytrance  ->  Psycore
  (688, 618), -- Darkstep  ->  Crossbreed
  (688, 2331), -- Darkstep  ->  Skullstep
  (690, 855), -- Darkwave  ->  Ethereal Wave
  (690, 1742), -- Darkwave  ->  Neoclassical Darkwave
  (690, 1757), -- Darkwave  ->  Neue Deutsche Todeskunst
  (696, 293), -- Death Metal  ->  Blackened Death Metal
  (696, 372), -- Death Metal  ->  Brutal Death Metal
  (696, 693), -- Death Metal  ->  Death 'n' Roll
  (696, 699), -- Death Metal  ->  Deathgrind
  (696, 1592), -- Death Metal  ->  Melodic Death Metal
  (696, 2512), -- Death Metal  ->  Technical Death Metal
  (698, 764), -- Deathcore  ->  Downtempo Deathcore
  (701, 1630), -- Deathstep  ->  Minatory
  (707, 1490), -- Deep House  ->  Lo-Fi House
  (711, 264), -- Delta Blues  ->  Bentonia School
  (714, 761), -- Demostyle  ->  Doskpop
  (718, 6), -- Descriptor  ->  A cappella
  (718, 26), -- Descriptor  ->  Acoustic Rock
  (718, 524), -- Descriptor  ->  Choral
  (718, 814), -- Descriptor  ->  Educational Music
  (718, 963), -- Descriptor  ->  French Pop
  (718, 1195), -- Descriptor  ->  Holiday Music
  (718, 1688), -- Descriptor  ->  Musical Parody
  (718, 1889), -- Descriptor  ->  Orchestral Music
  (718, 1987), -- Descriptor  ->  Polyphonic Chant
  (718, 2242), -- Descriptor  ->  Satire
  (718, 2379), -- Descriptor  ->  Soundtrack
  (718, 2717), -- Descriptor  ->  Vocal Group
  (721, 916), -- Detroit Sound  ->  Flint Sound
  (721, 1948), -- Detroit Sound  ->  Philly Drill
  (737, 315), -- Disco  ->  Boogie
  (737, 825), -- Disco  ->  Electro-Disco
  (737, 862), -- Disco  ->  Euro-Disco
  (737, 1456), -- Disco  ->  Latin Disco
  (737, 1693), -- Disco  ->  Mutant Disco
  (737, 1845), -- Disco  ->  Nu-Disco
  (742, 1142), -- Diva House  ->  Hardbag
  (746, 2539), -- Djent  ->  Thall
  (752, 175), -- Dominican Music  ->  Bachata
  (752, 712), -- Dominican Music  ->  Dembow
  (752, 1602), -- Dominican Music  ->  Merengue
  (757, 694), -- Doom Metal  ->  Death Doom Metal
  (757, 977), -- Doom Metal  ->  Funeral Doom Metal
  (757, 2583), -- Doom Metal  ->  Traditional Doom Metal
  (762, 2571), -- Doujin Music  ->  Touhou Music
  (763, 2610), -- Downtempo  ->  Trip Hop
  (769, 334), -- Drift Phonk  ->  Brazilian Phonk
  (769, 1952), -- Drift Phonk  ->  Phonk House
  (770, 495), -- Drill  ->  Chicago Drill
  (770, 949), -- Drill  ->  Free Car Music
  (770, 1324), -- Drill  ->  Jersey Drill
  (770, 1788), -- Drill  ->  New York Drill
  (770, 1948), -- Drill  ->  Philly Drill
  (770, 2654), -- Drill  ->  UK Drill
  (775, 153), -- Drum and Bass  ->  Atmospheric Drum and Bass
  (775, 666), -- Drum and Bass  ->  Dancefloor Drum and Bass
  (775, 688), -- Drum and Bass  ->  Darkstep
  (775, 705), -- Drum and Bass  ->  Deep Drum and Bass
  (775, 777), -- Drum and Bass  ->  Drumfunk
  (775, 780), -- Drum and Bass  ->  Drumstep
  (775, 788), -- Drum and Bass  ->  Dubwise Drum and Bass
  (775, 934), -- Drum and Bass  ->  Footwork Jungle
  (775, 1121), -- Drum and Bass  ->  Halftime
  (775, 1151), -- Drum and Bass  ->  Hardstep
  (775, 1318), -- Drum and Bass  ->  Jazzstep
  (775, 1346), -- Drum and Bass  ->  Jump-Up
  (775, 1348), -- Drum and Bass  ->  Jungle
  (775, 1480), -- Drum and Bass  ->  Liquid Drum and Bass
  (775, 1632), -- Drum and Bass  ->  Minimal Drum and Bass
  (775, 1760), -- Drum and Bass  ->  Neurofunk
  (775, 2517), -- Drum and Bass  ->  Technoid
  (775, 2518), -- Drum and Bass  ->  Techstep
  (775, 2595), -- Drum and Bass  ->  Trancestep
  (786, 370), -- Dubstep  ->  Brostep
  (786, 509), -- Dubstep  ->  Chillstep
  (786, 792), -- Dubstep  ->  Dungeon Sound
  (786, 1593), -- Dubstep  ->  Melodic Dubstep
  (786, 2075), -- Dubstep  ->  Purple Sound
  (786, 2141), -- Dubstep  ->  Riddim
  (786, 2508), -- Dubstep  ->  Tearout
  (793, 566), -- Dungeon Synth  ->  Comfy Synth
  (793, 1388), -- Dungeon Synth  ->  Keller Synth
  (793, 2756), -- Dungeon Synth  ->  Winter Synth
  (793, 2832), -- Dungeon Synth  ->  Dungeon Chip
  (797, 1808), -- Dutch House  ->  Noiadance
  (801, 13), -- East African Music  ->  Acholi Music
  (801, 178), -- East African Music  ->  Baganda Music
  (801, 260), -- East African Music  ->  Benga
  (801, 262), -- East African Music  ->  Beni
  (801, 313), -- East African Music  ->  Bongo Flava
  (801, 567), -- East African Music  ->  Comorian Music
  (801, 735), -- East African Music  ->  Dinka Music
  (801, 1045), -- East African Music  ->  Genge
  (801, 1069), -- East African Music  ->  Gogo Music
  (801, 1263), -- East African Music  ->  Inkiranya
  (801, 1376), -- East African Music  ->  Kapuka
  (801, 1399), -- East African Music  ->  Kidandali
  (801, 1400), -- East African Music  ->  Kidumbak
  (801, 1563), -- East African Music  ->  Marrabenta
  (801, 1582), -- East African Music  ->  Mchiriku
  (801, 1680), -- East African Music  ->  Mugithi
  (801, 1699), -- East African Music  ->  Muziki wa dansi
  (801, 1793), -- East African Music  ->  Ngoma
  (801, 1876), -- East African Music  ->  Omutibo
  (801, 2299), -- East African Music  ->  Shilluk Music
  (801, 2316), -- East African Music  ->  Singeli
  (801, 2353), -- East African Music  ->  Soga Music
  (801, 2477), -- East African Music  ->  Taarab
  (801, 2555), -- East African Music  ->  Timbila
  (801, 2643), -- East African Music  ->  Twa Music
  (802, 515), -- East Asian Classical Music  ->  Chinese Classical Music
  (802, 1299), -- East Asian Classical Music  ->  Japanese Classical Music
  (802, 1414), -- East Asian Classical Music  ->  Korean Classical Music
  (802, 2703), -- East Asian Classical Music  ->  Vietnamese Court Music
  (803, 77), -- East Asian Folk Music  ->  Amami shimauta
  (803, 516), -- East Asian Folk Music  ->  Chinese Folk Music
  (803, 1250), -- East Asian Folk Music  ->  Indigenous Taiwanese Music
  (803, 1300), -- East Asian Folk Music  ->  Japanese Folk Music
  (803, 1415), -- East Asian Folk Music  ->  Korean Folk Music
  (803, 2704), -- East Asian Folk Music  ->  Vietnamese Folk Music
  (804, 52), -- East Asian Music  ->  Ainu Music
  (804, 518), -- East Asian Music  ->  Chinese Music
  (804, 802), -- East Asian Music  ->  East Asian Classical Music
  (804, 803), -- East Asian Music  ->  East Asian Folk Music
  (804, 1304), -- East Asian Music  ->  Japanese Music
  (804, 1416), -- East Asian Music  ->  Korean Music
  (804, 1540), -- East Asian Music  ->  Manchu Music
  (804, 2195), -- East Asian Music  ->  Ryukyuan Music
  (804, 2705), -- East Asian Music  ->  Vietnamese Music
  (805, 203), -- East Coast Club  ->  Baltimore Club
  (805, 1322), -- East Coast Club  ->  Jersey Club
  (805, 1946), -- East Coast Club  ->  Philly Club
  (806, 367), -- East Coast Hip Hop  ->  Bronx Drill
  (806, 369), -- East Coast Hip Hop  ->  Brooklyn Drill
  (806, 747), -- East Coast Hip Hop  ->  DMV Hip Hop
  (807, 525), -- East Slavic Church Music  ->  Choral Concerto
  (807, 1441), -- East Slavic Church Music  ->  Kyivan Chant
  (807, 1767), -- East Slavic Church Music  ->  New Direction
  (807, 2811), -- East Slavic Church Music  ->  Znamenny Chant
  (809, 556), -- Easy Listening  ->  Cocktail Nation
  (809, 872), -- Easy Listening  ->  Exotica
  (809, 1478), -- Easy Listening  ->  Light Music
  (809, 1498), -- Easy Listening  ->  Lounge
  (809, 2003), -- Easy Listening  ->  Pops Orchestra
  (809, 2399), -- Easy Listening  ->  Space Age Pop
  (811, 680), -- EBM  ->  Dark Electro
  (811, 1008), -- EBM  ->  Futurepop
  (811, 1764), -- EBM  ->  New Beat
  (811, 2505), -- EBM  ->  TBM
  (816, 57), -- Egyptian Music  ->  Al jeel
  (816, 99), -- Egyptian Music  ->  Ancient Egyptian Music
  (816, 591), -- Egyptian Music  ->  Coptic Music
  (816, 2110), -- Egyptian Music  ->  Raqs baladi
  (816, 2198), -- Egyptian Music  ->  Sa'idi
  (816, 2285), -- Egyptian Music  ->  Shaabi
  (817, 353), -- Electric Blues  ->  British Blues
  (817, 494), -- Electric Blues  ->  Chicago Blues
  (817, 818), -- Electric Blues  ->  Electric Texas Blues
  (817, 2453), -- Electric Blues  ->  Swamp Blues
  (821, 569), -- Electro House  ->  Complextro
  (821, 797), -- Electro House  ->  Dutch House
  (821, 893), -- Electro House  ->  Fidget House
  (821, 959), -- Electro House  ->  French Electro
  (821, 1589), -- Electro House  ->  Melbourne Bounce
  (825, 1173), -- Electro-Disco  ->  Hi-NRG
  (825, 1284), -- Electro-Disco  ->  Italo-Disco
  (825, 2122), -- Electro-Disco  ->  Red Disco
  (825, 2401), -- Electro-Disco  ->  Space Disco
  (826, 680), -- Electro-Industrial  ->  Dark Electro
  (827, 23), -- Electroacoustic  ->  Acousmatic Music
  (827, 799), -- Electroacoustic  ->  EAI
  (827, 1691), -- Electroacoustic  ->  Musique concrète
  (829, 14), -- Electronic  ->  Acholitronix
  (829, 63), -- Electronic  ->  Algorave
  (829, 278), -- Electronic  ->  Binaural Beats
  (829, 282), -- Electronic  ->  Bit Music
  (829, 283), -- Electronic  ->  Bitpop
  (829, 458), -- Electronic  ->  Celtic Electronica
  (829, 508), -- Electronic  ->  Chillout
  (829, 731), -- Electronic  ->  Digital Fusion
  (829, 769), -- Electronic  ->  Drift Phonk
  (829, 793), -- Electronic  ->  Dungeon Synth
  (829, 820), -- Electronic  ->  Electro Hop
  (829, 826), -- Electronic  ->  Electro-Industrial
  (829, 827), -- Electronic  ->  Electroacoustic
  (829, 830), -- Electronic  ->  Electronic Dance Music
  (829, 832), -- Electronic  ->  Electropop
  (829, 851), -- Electronic  ->  Epic Collage
  (829, 913), -- Electronic  ->  Flashcore
  (829, 929), -- Electronic  ->  Folktronica
  (829, 995), -- Electronic  ->  Funktronica
  (829, 1061), -- Electronic  ->  Glitch
  (829, 1062), -- Electronic  ->  Glitch Hop
  (829, 1084), -- Electronic  ->  Graphical Sound
  (829, 1172), -- Electronic  ->  HexD
  (829, 1204), -- Electronic  ->  Horror Synth
  (829, 1219), -- Electronic  ->  Hyperpop
  (829, 1228), -- Electronic  ->  IDM
  (829, 1232), -- Electronic  ->  Illbient
  (829, 1244), -- Electronic  ->  Indietronica
  (829, 1457), -- Electronic  ->  Latin Electronic
  (829, 1486), -- Electronic  ->  Livetronica
  (829, 1535), -- Electronic  ->  Maloya électronique
  (829, 1616), -- Electronic  ->  Micromontage
  (829, 1635), -- Electronic  ->  Minimal Wave
  (829, 1659), -- Electronic  ->  Moogsploitation
  (829, 1799), -- Electronic  ->  Nightcore
  (829, 1841), -- Electronic  ->  Nu Jazz
  (829, 2023), -- Electronic  ->  Power Electronics
  (829, 2025), -- Electronic  ->  Power Noise
  (829, 2043), -- Electronic  ->  Progressive Electronic
  (829, 2400), -- Electronic  ->  Space Ambient
  (829, 2469), -- Electronic  ->  Synth Punk
  (829, 2470), -- Electronic  ->  Synthpop
  (829, 2471), -- Electronic  ->  Synthwave
  (829, 2521), -- Electronic  ->  Tecnobrega
  (829, 2693), -- Electronic  ->  Vapor
  (829, 2738), -- Electronic  ->  Wave
  (829, 2757), -- Electronic  ->  Witch House
  (830, 139), -- Electronic Dance Music  ->  Artcore
  (830, 188), -- Electronic Dance Music  ->  Balani Show
  (830, 189), -- Electronic Dance Music  ->  Balearic Beat
  (830, 336), -- Electronic Dance Music  ->  Breakbeat
  (830, 365), -- Electronic Dance Music  ->  Broken Beat
  (830, 375), -- Electronic Dance Music  ->  Bubblegum Bass
  (830, 377), -- Electronic Dance Music  ->  Bubbling
  (830, 381), -- Electronic Dance Music  ->  Budots
  (830, 396), -- Electronic Dance Music  ->  Bérite Club
  (830, 609), -- Electronic Dance Music  ->  Coupé-décalé
  (830, 620), -- Electronic Dance Music  ->  Cruise
  (830, 676), -- Electronic Dance Music  ->  Dariacore
  (830, 679), -- Electronic Dance Music  ->  Dark Disco
  (830, 703), -- Electronic Dance Music  ->  Deconstructed Club
  (830, 710), -- Electronic Dance Music  ->  Dek Bass
  (830, 729), -- Electronic Dance Music  ->  Digital Cumbia
  (830, 775), -- Electronic Dance Music  ->  Drum and Bass
  (830, 786), -- Electronic Dance Music  ->  Dubstep
  (830, 805), -- Electronic Dance Music  ->  East Coast Club
  (830, 811), -- Electronic Dance Music  ->  EBM
  (830, 819), -- Electronic Dance Music  ->  Electro
  (830, 822), -- Electronic Dance Music  ->  Electro latino
  (830, 823), -- Electronic Dance Music  ->  Electro Swing
  (830, 825), -- Electronic Dance Music  ->  Electro-Disco
  (830, 828), -- Electronic Dance Music  ->  Electroclash
  (830, 864), -- Electronic Dance Music  ->  Eurobeat
  (830, 865), -- Electronic Dance Music  ->  Eurodance
  (830, 915), -- Electronic Dance Music  ->  Flex Dance Music
  (830, 933), -- Electronic Dance Music  ->  Footwork
  (830, 956), -- Electronic Dance Music  ->  Freestyle
  (830, 987), -- Electronic Dance Music  ->  Funk mandelão
  (830, 994), -- Electronic Dance Music  ->  Funkot
  (830, 1000), -- Electronic Dance Music  ->  Future Bass
  (830, 1006), -- Electronic Dance Music  ->  Future Rave
  (830, 1053), -- Electronic Dance Music  ->  Ghettotech
  (830, 1063), -- Electronic Dance Music  ->  Glitch Hop [EDM]
  (830, 1082), -- Electronic Dance Music  ->  Gqom
  (830, 1091), -- Electronic Dance Music  ->  Grime
  (830, 1136), -- Electronic Dance Music  ->  Hard Dance
  (830, 1137), -- Electronic Dance Music  ->  Hard Drum
  (830, 1144), -- Electronic Dance Music  ->  Hardcore [EDM]
  (830, 1154), -- Electronic Dance Music  ->  Hardtekk
  (830, 1155), -- Electronic Dance Music  ->  Hardvapour
  (830, 1156), -- Electronic Dance Music  ->  Hardwave
  (830, 1207), -- Electronic Dance Music  ->  House
  (830, 1218), -- Electronic Dance Music  ->  Hyper Techno
  (830, 1220), -- Electronic Dance Music  ->  Hypertechno
  (830, 1350), -- Electronic Dance Music  ->  Jungle Terror
  (830, 1425), -- Electronic Dance Music  ->  Krushclub
  (830, 1428), -- Electronic Dance Music  ->  Kuduro
  (830, 1521), -- Electronic Dance Music  ->  Makina
  (830, 1549), -- Electronic Dance Music  ->  Manyao
  (830, 1590), -- Electronic Dance Music  ->  Melodic Bass
  (830, 1621), -- Electronic Dance Music  ->  Midtempo Bass
  (830, 1660), -- Electronic Dance Music  ->  Moombahcore
  (830, 1661), -- Electronic Dance Music  ->  Moombahton
  (830, 1754), -- Electronic Dance Music  ->  Nerdcore Techno
  (830, 1845), -- Electronic Dance Music  ->  Nu-Disco
  (830, 1892), -- Electronic Dance Music  ->  Ori deck
  (830, 1902), -- Electronic Dance Music  ->  Outrun
  (830, 2014), -- Electronic Dance Music  ->  Post-Dubstep
  (830, 2289), -- Electronic Dance Music  ->  Shangaan Electro
  (830, 2316), -- Electronic Dance Music  ->  Singeli
  (830, 2332), -- Electronic Dance Music  ->  Skweee
  (830, 2340), -- Electronic Dance Music  ->  Slimepunk
  (830, 2514), -- Electronic Dance Music  ->  Techno
  (830, 2515), -- Electronic Dance Music  ->  Techno Bass
  (830, 2524), -- Electronic Dance Music  ->  Tecnorumba
  (830, 2592), -- Electronic Dance Music  ->  Trance
  (830, 2597), -- Electronic Dance Music  ->  Trap [EDM]
  (830, 2607), -- Electronic Dance Music  ->  Tribal Guarachero
  (830, 2653), -- Electronic Dance Music  ->  UK Bass
  (830, 2655), -- Electronic Dance Music  ->  UK Funky
  (830, 2656), -- Electronic Dance Music  ->  UK Garage
  (830, 2762), -- Electronic Dance Music  ->  Wonky
  (838, 841), -- Emo  ->  Emo-Pop
  (838, 842), -- Emo  ->  Emocore
  (838, 1532), -- Emo  ->  Mall Screamo
  (838, 1622), -- Emo  ->  Midwest Emo
  (838, 2255), -- Emo  ->  Screamo
  (844, 592), -- English Folk Music  ->  Cornish Folk Music
  (844, 1668), -- English Folk Music  ->  Morris Music
  (844, 1829), -- English Folk Music  ->  Northumbrian Folk Music
  (844, 2256), -- English Folk Music  ->  Scrumpy and Western
  (846, 1447), -- English Underground  ->  Ladbroke Grove Scene
  (848, 849), -- Entechna  ->  Entechna laika
  (848, 1729), -- Entechna  ->  Neo Kyma
  (854, 2280), -- Estonian Folk Music  ->  Seto leelo
  (858, 173), -- Ethiopic Music  ->  Azmari
  (858, 856), -- Ethiopic Music  ->  Ethio-Jazz
  (858, 857), -- Ethiopic Music  ->  Ethiopian Church Music
  (858, 1111), -- Ethiopic Music  ->  Gurage Music
  (858, 1550), -- Ethiopic Music  ->  Manzuma
  (858, 2553), -- Ethiopic Music  ->  Tigrinya Music
  (858, 2559), -- Ethiopic Music  ->  Tizita
  (860, 1142), -- Euro House  ->  Hardbag
  (861, 1126), -- Euro Trance  ->  Hands Up
  (864, 1288), -- Eurobeat  ->  J-Euro
  (865, 376), -- Eurodance  ->  Bubblegum Dance
  (865, 1281), -- Eurodance  ->  Italo Dance
  (866, 66), -- European Folk Music  ->  Alpine Folk Music
  (866, 194), -- European Folk Music  ->  Balkan Folk Music
  (866, 202), -- European Folk Music  ->  Baltic Folk Music
  (866, 204), -- European Folk Music  ->  Balto-Finnic Folk Music
  (866, 226), -- European Folk Music  ->  Basque Folk Music
  (866, 453), -- European Folk Music  ->  Catalan Folk Music
  (866, 459), -- European Folk Music  ->  Celtic Folk Music
  (866, 796), -- European Folk Music  ->  Dutch Folk Music
  (866, 844), -- European Folk Music  ->  English Folk Music
  (866, 914), -- European Folk Music  ->  Flemish Folk Music
  (866, 960), -- European Folk Music  ->  French Folk Music
  (866, 1048), -- European Folk Music  ->  German Folk Music
  (866, 1115), -- European Folk Music  ->  Għana
  (866, 1212), -- European Folk Music  ->  Hungarian Folk Music
  (866, 1278), -- European Folk Music  ->  Istrian Folk Music
  (866, 1279), -- European Folk Music  ->  Italian Folk Music
  (866, 1507), -- European Folk Music  ->  Luxembourgish Folk Music
  (866, 1736), -- European Folk Music  ->  Neo-Medieval Folk
  (866, 1737), -- European Folk Music  ->  Neo-Pagan Folk
  (866, 1815), -- European Folk Music  ->  Nordic Folk Music
  (866, 1981), -- European Folk Music  ->  Polka
  (866, 2007), -- European Folk Music  ->  Portuguese Folk Music
  (866, 2174), -- European Folk Music  ->  Romani Folk Music
  (866, 2176), -- European Folk Music  ->  Romanian Folk Music
  (866, 2338), -- European Folk Music  ->  Slavic Folk Music
  (866, 2407), -- European Folk Music  ->  Spanish Folk Music
  (866, 2724), -- European Folk Music  ->  Volga-Ural Folk Music
  (866, 2731), -- European Folk Music  ->  Walloon Folk Music
  (866, 2754), -- European Folk Music  ->  White Voice
  (866, 2783), -- European Folk Music  ->  Yiddish Folksong
  (868, 65), -- European Music  ->  Alpenrock
  (868, 103), -- European Music  ->  Ancient Roman Music
  (868, 107), -- European Music  ->  Anglican Chant
  (868, 141), -- European Music  ->  Ashkenazi Music
  (868, 195), -- European Music  ->  Balkan Music
  (868, 221), -- European Music  ->  Baroque Music
  (868, 223), -- European Music  ->  Baroque Suite
  (868, 357), -- European Music  ->  British Music
  (868, 455), -- European Music  ->  Caucasian Music
  (868, 458), -- European Music  ->  Celtic Electronica
  (868, 460), -- European Music  ->  Celtic Metal
  (868, 461), -- European Music  ->  Celtic New Age
  (868, 462), -- European Music  ->  Celtic Punk
  (868, 463), -- European Music  ->  Celtic Rock
  (868, 484), -- European Music  ->  Chanson
  (868, 551), -- European Music  ->  Classical Period
  (868, 598), -- European Music  ->  Country & Irish
  (868, 615), -- European Music  ->  Crimean Tatar Music
  (868, 702), -- European Music  ->  Dechovka
  (868, 795), -- European Music  ->  Dutch Cabaret
  (868, 807), -- European Music  ->  East Slavic Church Music
  (868, 866), -- European Music  ->  European Folk Music
  (868, 886), -- European Music  ->  Fanfare
  (868, 1049), -- European Music  ->  German Music
  (868, 1083), -- European Music  ->  Grand opéra
  (868, 1087), -- European Music  ->  Greek Music
  (868, 1202), -- European Music  ->  Hornpipe
  (868, 1225), -- European Music  ->  Iberian Music
  (868, 1274), -- European Music  ->  Irish Showband
  (868, 1280), -- European Music  ->  Italian Music
  (868, 1355), -- European Music  ->  Kabarett
  (868, 1367), -- European Music  ->  Kalmyk Music
  (868, 1407), -- European Music  ->  Kleinkunst
  (868, 1513), -- European Music  ->  Madrigal
  (868, 1584), -- European Music  ->  Medieval Classical Music
  (868, 1640), -- European Music  ->  Mittelalter-Metal
  (868, 1641), -- European Music  ->  Mittelalter-Rock
  (868, 1681), -- European Music  ->  Mulatós
  (868, 1700), -- European Music  ->  Mélodie
  (868, 1817), -- European Music  ->  Nordic Music
  (868, 1862), -- European Music  ->  Nòva cançon
  (868, 1887), -- European Music  ->  Opéra-comique
  (868, 1979), -- European Music  ->  Polish Music
  (868, 2131), -- European Music  ->  Renaissance Music
  (868, 2177), -- European Music  ->  Romanian Music
  (868, 2193), -- European Music  ->  Russian Music
  (868, 2247), -- European Music  ->  Schlager
  (868, 2248), -- European Music  ->  Schottische
  (868, 2318), -- European Music  ->  Singspiel
  (868, 2589), -- European Music  ->  Tragédie en musique
  (868, 2591), -- European Music  ->  Trampská hudba
  (868, 2701), -- European Music  ->  Verismo
  (868, 2732), -- European Music  ->  Waltz
  (871, 47), -- Ewe Music  ->  Agbadza
  (871, 48), -- Ewe Music  ->  Agbekor
  (872, 2321), -- Exotica  ->  Sitarsploitation
  (873, 577), -- Experimental  ->  Conducted Improvisation
  (873, 692), -- Experimental  ->  Data Sonification
  (873, 773), -- Experimental  ->  Drone
  (873, 827), -- Experimental  ->  Electroacoustic
  (873, 952), -- Experimental  ->  Free Improvisation
  (873, 1009), -- Experimental  ->  Futurism
  (873, 1061), -- Experimental  ->  Glitch
  (873, 1084), -- Experimental  ->  Graphical Sound
  (873, 1236), -- Experimental  ->  Indeterminacy
  (873, 1255), -- Experimental  ->  Industrial
  (873, 1648), -- Experimental  ->  Modern Creative
  (873, 1692), -- Experimental  ->  Musique concrète instrumentale
  (873, 1809), -- Experimental  ->  Noise
  (873, 1973), -- Experimental  ->  Plunderphonics
  (873, 2123), -- Experimental  ->  Reductionism
  (873, 2374), -- Experimental  ->  Sound Art
  (873, 2375), -- Experimental  ->  Sound Collage
  (873, 2377), -- Experimental  ->  Sound Poetry
  (873, 2495), -- Experimental  ->  Tape Music
  (873, 2639), -- Experimental  ->  Turntable Music
  (875, 1259), -- Experimental Hip Hop  ->  Industrial Hip Hop
  (876, 165), -- Experimental Rock  ->  Avant-Prog
  (876, 1421), -- Experimental Rock  ->  Krautrock
  (879, 880), -- Fado  ->  Fado de Coimbra
  (884, 885), -- Fandango  ->  Fandango caiçara
  (896, 1723), -- Field Recordings  ->  Nature Recordings
  (896, 2093), -- Field Recordings  ->  Radio Broadcast Recordings
  (899, 2727), -- Fijian Music  ->  Vude
  (904, 903), -- Film Soundtrack  ->  Film Score
  (904, 905), -- Film Soundtrack  ->  Filmi
  (909, 385), -- Flamenco  ->  Bulería
  (909, 911), -- Flamenco  ->  Flamenco nuevo
  (909, 2188), -- Flamenco  ->  Rumba flamenca
  (911, 910), -- Flamenco nuevo  ->  Flamenco Jazz
  (920, 584), -- Folk  ->  Contemporary Folk
  (920, 2584), -- Folk  ->  Traditional Folk Music
  (922, 460), -- Folk Metal  ->  Celtic Metal
  (922, 1640), -- Folk Metal  ->  Mittelalter-Metal
  (923, 2431), -- Folk Pop  ->  Stomp and Holler
  (924, 462), -- Folk Punk  ->  Celtic Punk
  (924, 1113), -- Folk Punk  ->  Gypsy Punk
  (925, 65), -- Folk Rock  ->  Alpenrock
  (925, 356), -- Folk Rock  ->  British Folk Rock
  (925, 463), -- Folk Rock  ->  Celtic Rock
  (925, 1641), -- Folk Rock  ->  Mittelalter-Rock
  (925, 1816), -- Folk Rock  ->  Nordic Folk Rock
  (925, 1950), -- Folk Rock  ->  Phleng phuea chiwit
  (925, 1960), -- Folk Rock  ->  Pinoy Folk Rock
  (925, 2163), -- Folk Rock  ->  Rock rural
  (927, 2736), -- Folklor miejski  ->  Warsaw City Folk
  (931, 2506), -- Fon Music  ->  Tchink System
  (931, 2507), -- Fon Music  ->  Tchinkoumé
  (931, 2810), -- Fon Music  ->  Zinli
  (933, 934), -- Footwork  ->  Footwork Jungle
  (936, 938), -- Forró  ->  Forró eletrônico
  (936, 939), -- Forró  ->  Forró universitário
  (938, 937), -- Forró eletrônico  ->  Forró de favela
  (938, 1966), -- Forró eletrônico  ->  Piseiro
  (952, 799), -- Free Improvisation  ->  EAI
  (952, 2858), -- Free Improvisation  ->  Echtzeitmusik
  (953, 867), -- Free Jazz  ->  European Free Jazz
  (956, 1458), -- Freestyle  ->  Latin Freestyle
  (958, 256), -- French Caribbean Music  ->  Bele
  (958, 276), -- French Caribbean Music  ->  Biguine
  (958, 327), -- French Caribbean Music  ->  Bouyon
  (958, 402), -- French Caribbean Music  ->  Cadence Lypso
  (958, 715), -- French Caribbean Music  ->  Dennery Segment
  (958, 1112), -- French Caribbean Music  ->  Gwo ka
  (958, 1119), -- French Caribbean Music  ->  Haitian Music
  (958, 1426), -- French Caribbean Music  ->  Kréyol djaz
  (958, 2628), -- French Caribbean Music  ->  Tumbélé
  (958, 2816), -- French Caribbean Music  ->  Zouk
  (960, 67), -- French Folk Music  ->  Alsatian Folk Music
  (960, 346), -- French Folk Music  ->  Breton Folk Music
  (960, 595), -- French Folk Music  ->  Corsican Folk Music
  (960, 1685), -- French Folk Music  ->  Musette
  (960, 1866), -- French Folk Music  ->  Occitan Folk Music
  (966, 967), -- Frevo  ->  Frevo de bloco
  (966, 968), -- Frevo  ->  Frevo de rua
  (966, 969), -- Frevo  ->  Frevo elétrico
  (966, 970), -- Frevo  ->  Frevo-canção
  (980, 39), -- Funk  ->  Afro-Funk
  (980, 351), -- Funk  ->  Britfunk
  (980, 706), -- Funk  ->  Deep Funk
  (980, 1066), -- Funk  ->  Go-Go
  (980, 1316), -- Funk  ->  Jazz-Funk
  (980, 1459), -- Funk  ->  Latin Funk
  (980, 1905), -- Funk  ->  P-Funk
  (980, 2004), -- Funk  ->  Porn Groove
  (980, 2468), -- Funk  ->  Synth Funk
  (983, 129), -- Funk brasileiro  ->  Arrocha funk
  (983, 243), -- Funk brasileiro  ->  Beat bolha
  (983, 245), -- Funk brasileiro  ->  Beat fino
  (983, 343), -- Funk brasileiro  ->  Brega funk
  (983, 835), -- Funk brasileiro  ->  Eletrofunk
  (983, 981), -- Funk brasileiro  ->  Funk 150 bpm
  (983, 984), -- Funk brasileiro  ->  Funk carioca
  (983, 985), -- Funk brasileiro  ->  Funk consciente
  (983, 986), -- Funk brasileiro  ->  Funk de BH
  (983, 987), -- Funk brasileiro  ->  Funk mandelão
  (983, 988), -- Funk brasileiro  ->  Funk Melody
  (983, 990), -- Funk brasileiro  ->  Funk ostentação
  (983, 993), -- Funk brasileiro  ->  Funknejo
  (983, 1586), -- Funk brasileiro  ->  Mega funk
  (983, 1808), -- Funk brasileiro  ->  Noiadance
  (983, 2115), -- Funk brasileiro  ->  Rasteirinha
  (983, 2522), -- Funk brasileiro  ->  Tecnofunk
  (983, 2604), -- Funk brasileiro  ->  Trapfunk
  (984, 991), -- Funk carioca  ->  Funk proibidão
  (984, 2488), -- Funk carioca  ->  Tamborzão
  (987, 244), -- Funk mandelão  ->  Beat bruxaria
  (987, 334), -- Funk mandelão  ->  Brazilian Phonk
  (987, 982), -- Funk mandelão  ->  Funk automotivo
  (987, 2147), -- Funk mandelão  ->  Ritmada
  (992, 989), -- Funk Rock  ->  Funk Metal
  (994, 338), -- Funkot  ->  Breakbeat Kota
  (1000, 1382), -- Future Bass  ->  Kawaii Future Bass
  (1005, 1001), -- Future House  ->  Future Bounce
  (1005, 2337), -- Future House  ->  Slap House
  (1014, 1844), -- Gabber  ->  Nu Style Gabber
  (1022, 190), -- Gamelan  ->  Balinese Gamelan
  (1022, 1025), -- Gamelan  ->  Gamelan beleganjur
  (1022, 1026), -- Gamelan  ->  Gamelan degung
  (1022, 1032), -- Gamelan  ->  Gamelan selonding
  (1022, 1305), -- Gamelan  ->  Javanese Gamelan
  (1022, 1528), -- Gamelan  ->  Malay Gamelan
  (1035, 558), -- Gangsta Rap  ->  Coke Rap
  (1035, 1514), -- Gangsta Rap  ->  Mafioso Rap
  (1035, 2151), -- Gangsta Rap  ->  Road Rap
  (1035, 2245), -- Gangsta Rap  ->  Scam Rap
  (1035, 2859), -- Gangsta Rap  ->  Pimp Rap
  (1036, 1077), -- Garage House  ->  Gospel House
  (1036, 1326), -- Garage House  ->  Jersey Sound
  (1039, 946), -- Garage Rock  ->  Frat Rock
  (1039, 948), -- Garage Rock  ->  Freakbeat
  (1039, 1037), -- Garage Rock  ->  Garage Psych
  (1039, 1038), -- Garage Rock  ->  Garage Punk
  (1039, 1040), -- Garage Rock  ->  Garage Rock Revival
  (1039, 2835), -- Garage Rock  ->  Budget Rock
  (1042, 2074), -- Garifuna Folk Music  ->  Punta
  (1045, 1046), -- Genge  ->  Gengetone
  (1047, 232), -- Georgian Folk Music  ->  Batonebi Songs
  (1048, 1097), -- German Folk Music  ->  Gstanzl
  (1048, 1936), -- German Folk Music  ->  Pennsylvania Dutch Folk Music
  (1049, 67), -- German Music  ->  Alsatian Folk Music
  (1049, 1048), -- German Music  ->  German Folk Music
  (1049, 1106), -- German Music  ->  Guggenmusik
  (1049, 1476), -- German Music  ->  Lied
  (1049, 1477), -- German Music  ->  Liedermacher
  (1049, 1507), -- German Music  ->  Luxembourgish Folk Music
  (1049, 1508), -- German Music  ->  Ländler
  (1049, 2181), -- German Music  ->  Romantische Oper
  (1049, 2725), -- German Music  ->  Volkstümliche Musik
  (1049, 2800), -- German Music  ->  Zeitoper
  (1052, 1344), -- Ghetto House  ->  Juke
  (1058, 2339), -- Glam Metal  ->  Sleaze Rock
  (1060, 1059), -- Glam Rock  ->  Glam Punk
  (1063, 1051), -- Glitch Hop [EDM]  ->  Ghetto Funk
  (1063, 1761), -- Glitch Hop [EDM]  ->  Neurohop
  (1066, 325), -- Go-Go  ->  Bounce Beat
  (1067, 1802), -- Goa Trance  ->  Nitzhonot
  (1073, 1978), -- Goral Music  ->  Polish Goral Music
  (1074, 1075), -- Goregrind  ->  Gorenoise
  (1074, 2005), -- Goregrind  ->  Pornogrind
  (1076, 287), -- Gospel  ->  Black Gospel
  (1076, 602), -- Gospel  ->  Country Gospel
  (1076, 2392), -- Gospel  ->  Southern Gospel
  (1081, 700), -- Gothic Rock  ->  Deathrock
  (1081, 2009), -- Gothic Rock  ->  Positive Punk
  (1086, 30), -- Greek Folk Music  ->  Aegean Islands Folk Music
  (1086, 613), -- Greek Folk Music  ->  Cretan Folk Music
  (1086, 734), -- Greek Folk Music  ->  Dimotika
  (1086, 1271), -- Greek Folk Music  ->  Ionian Islands Folk Music
  (1086, 2130), -- Greek Folk Music  ->  Rembetika
  (1087, 100), -- Greek Music  ->  Ancient Greek Music
  (1087, 395), -- Greek Music  ->  Byzantine Music
  (1087, 848), -- Greek Music  ->  Entechna
  (1087, 1086), -- Greek Music  ->  Greek Folk Music
  (1087, 1449), -- Greek Music  ->  Laika
  (1088, 1365), -- Greenlandic Music  ->  Kalattut
  (1088, 2558), -- Greenlandic Music  ->  Tivaner inngernerlu
  (1088, 2650), -- Greenlandic Music  ->  Uaajeerneq
  (1088, 2685), -- Greenlandic Music  ->  Vaigat
  (1090, 2240), -- Gregorian Chant  ->  Sarum Chant
  (1091, 1735), -- Grime  ->  Neo-Grime
  (1091, 2739), -- Grime  ->  Weightless
  (1092, 654), -- Grindcore  ->  Cybergrind
  (1092, 699), -- Grindcore  ->  Deathgrind
  (1092, 1074), -- Grindcore  ->  Goregrind
  (1092, 1631), -- Grindcore  ->  Mincecore
  (1092, 1813), -- Grindcore  ->  Noisegrind
  (1119, 403), -- Haitian Music  ->  Cadence rampa
  (1119, 568), -- Haitian Music  ->  Compas
  (1119, 1120), -- Haitian Music  ->  Haitian Vodou Drumming
  (1119, 1701), -- Haitian Music  ->  Méringue
  (1119, 2092), -- Haitian Music  ->  Rabòday
  (1119, 2111), -- Haitian Music  ->  Rara
  (1119, 2113), -- Haitian Music  ->  Rasin
  (1119, 2648), -- Haitian Music  ->  Twoubadou
  (1126, 379), -- Hands Up  ->  Buchiage Trance
  (1130, 326), -- Happy Hardcore  ->  Bouncy Techno
  (1130, 2658), -- Happy Hardcore  ->  UK Hardcore
  (1136, 1140), -- Hard Dance  ->  Hard Trance
  (1136, 1152), -- Hard Dance  ->  Hardstyle
  (1136, 1153), -- Hard Dance  ->  Hardtek
  (1136, 1347), -- Hard Dance  ->  Jumpstyle
  (1136, 1472), -- Hard Dance  ->  Lento violento
  (1136, 1730), -- Hard Dance  ->  Neo Rave
  (1136, 1840), -- Hard Dance  ->  NRG
  (1136, 2657), -- Hard Dance  ->  UK Hard House
  (1136, 2658), -- Hard Dance  ->  UK Hardcore
  (1138, 1058), -- Hard Rock  ->  Glam Metal
  (1138, 1168), -- Hard Rock  ->  Heavy Psych
  (1138, 1867), -- Hard Rock  ->  Occult Rock
  (1138, 2159), -- Hard Rock  ->  Rock Kapak
  (1138, 2434), -- Hard Rock  ->  Stoner Rock
  (1139, 2249), -- Hard Techno  ->  Schranz
  (1144, 22), -- Hardcore [EDM]  ->  Acidcore
  (1144, 95), -- Hardcore [EDM]  ->  Amigacore
  (1144, 257), -- Hardcore [EDM]  ->  Belgian Techno
  (1144, 337), -- Hardcore [EDM]  ->  Breakbeat Hardcore
  (1144, 339), -- Hardcore [EDM]  ->  Breakcore
  (1144, 618), -- Hardcore [EDM]  ->  Crossbreed
  (1144, 686), -- Hardcore [EDM]  ->  Darkcore
  (1144, 697), -- Hardcore [EDM]  ->  Deathchant Hardcore
  (1144, 732), -- Hardcore [EDM]  ->  Digital Hardcore
  (1144, 759), -- Hardcore [EDM]  ->  Doomcore
  (1144, 944), -- Hardcore [EDM]  ->  Frapcore
  (1144, 955), -- Hardcore [EDM]  ->  Freeform Hardcore
  (1144, 965), -- Hardcore [EDM]  ->  Frenchcore
  (1144, 1014), -- Hardcore [EDM]  ->  Gabber
  (1144, 1130), -- Hardcore [EDM]  ->  Happy Hardcore
  (1144, 1153), -- Hardcore [EDM]  ->  Hardtek
  (1144, 1258), -- Hardcore [EDM]  ->  Industrial Hardcore
  (1144, 2414), -- Hardcore [EDM]  ->  Speedcore
  (1144, 2531), -- Hardcore [EDM]  ->  Terrorcore
  (1144, 2672), -- Hardcore [EDM]  ->  Uptempo Hardcore
  (1145, 249), -- Hardcore [Punk]  ->  Beatdown Hardcore
  (1145, 831), -- Hardcore [Punk]  ->  Electronicore
  (1145, 1092), -- Hardcore [Punk]  ->  Grindcore
  (1145, 1148), -- Hardcore [Punk]  ->  Hardcore Punk
  (1145, 1609), -- Hardcore [Punk]  ->  Metalcore
  (1145, 1801), -- Hardcore [Punk]  ->  Nintendocore
  (1145, 1812), -- Hardcore [Punk]  ->  Noisecore
  (1145, 2016), -- Hardcore [Punk]  ->  Post-Hardcore
  (1145, 2241), -- Hardcore [Punk]  ->  Sass
  (1147, 350), -- Hardcore Hip Hop  ->  Britcore
  (1147, 523), -- Hardcore Hip Hop  ->  Chopper
  (1147, 1035), -- Hardcore Hip Hop  ->  Gangsta Rap
  (1147, 1205), -- Hardcore Hip Hop  ->  Horrorcore
  (1147, 1598), -- Hardcore Hip Hop  ->  Memphis Rap
  (1147, 1619), -- Hardcore Hip Hop  ->  Mid-School Hip Hop
  (1147, 2600), -- Hardcore Hip Hop  ->  Trap Metal
  (1148, 390), -- Hardcore Punk  ->  Burning Spirits
  (1148, 619), -- Hardcore Punk  ->  Crossover Thrash
  (1148, 623), -- Hardcore Punk  ->  Crust Punk
  (1148, 657), -- Hardcore Punk  ->  D-Beat
  (1148, 1594), -- Hardcore Punk  ->  Melodic Hardcore
  (1148, 1631), -- Hardcore Punk  ->  Mincecore
  (1148, 2325), -- Hardcore Punk  ->  Skacore
  (1148, 2437), -- Hardcore Punk  ->  Street Punk
  (1148, 2548), -- Hardcore Punk  ->  Thrashcore
  (1148, 2837), -- Hardcore Punk  ->  Tough Guy Hardcore
  (1148, 2838), -- Hardcore Punk  ->  Los Angeles Hardcore
  (1152, 787), -- Hardstyle  ->  Dubstyle
  (1152, 800), -- Hardstyle  ->  Early Hardstyle
  (1152, 859), -- Hardstyle  ->  Euphoric Hardstyle
  (1152, 1859), -- Hardstyle  ->  Nustyle
  (1152, 2064), -- Hardstyle  ->  Psystyle
  (1152, 2119), -- Hardstyle  ->  Rawstyle
  (1153, 2100), -- Hardtek  ->  Raggatek
  (1158, 1159), -- Harsh Noise  ->  Harsh Noise Wall
  (1160, 1800), -- Hasidic Music  ->  Nigun
  (1163, 1129), -- Hawaiian Music  ->  Hapa haole
  (1163, 1307), -- Hawaiian Music  ->  Jawaiian
  (1163, 2333), -- Hawaiian Music  ->  Slack-Key Guitar
  (1167, 2413), -- Heavy Metal  ->  Speed Metal
  (1167, 2678), -- Heavy Metal  ->  US Power Metal
  (1172, 1425), -- HexD  ->  Krushclub
  (1177, 388), -- Highlife  ->  Burger-Highlife
  (1179, 1191), -- Hill Tribe Music  ->  Hmong Folk Music
  (1179, 1192), -- Hill Tribe Music  ->  Hmong Pop
  (1179, 1483), -- Hill Tribe Music  ->  Lisu Music
  (1181, 727), -- Hindustani Classical Music  ->  Dhrupad
  (1181, 1360), -- Hindustani Classical Music  ->  Kafi
  (1181, 1394), -- Hindustani Classical Music  ->  Khayal
  (1181, 1406), -- Hindustani Classical Music  ->  Klasik
  (1181, 2084), -- Hindustani Classical Music  ->  Qawwali
  (1181, 2286), -- Hindustani Classical Music  ->  Shabad kirtan
  (1181, 2498), -- Hindustani Classical Music  ->  Tarana
  (1181, 2549), -- Hindustani Classical Music  ->  Thumri
  (1182, 12), -- Hip Hop  ->  Abstract Hip Hop
  (1182, 37), -- Hip Hop  ->  Afro Trap
  (1182, 46), -- Hip Hop  ->  Afroswing
  (1182, 115), -- Hip Hop  ->  Arabesque Rap
  (1182, 233), -- Hip Hop  ->  Battle Rap
  (1182, 313), -- Hip Hop  ->  Bongo Flava
  (1182, 318), -- Hip Hop  ->  Boom Bap
  (1182, 324), -- Hip Hop  ->  Bounce
  (1182, 520), -- Hip Hop  ->  Chipmunk Soul
  (1182, 522), -- Hip Hop  ->  Chopped and Screwed
  (1182, 530), -- Hip Hop  ->  Christian Hip Hop
  (1182, 554), -- Hip Hop  ->  Cloud Rap
  (1182, 564), -- Hip Hop  ->  Comedy Rap
  (1182, 581), -- Hip Hop  ->  Conscious Hip Hop
  (1182, 604), -- Hip Hop  ->  Country Rap
  (1182, 621), -- Hip Hop  ->  Crunk
  (1182, 622), -- Hip Hop  ->  Crunkcore
  (1182, 721), -- Hip Hop  ->  Detroit Sound
  (1182, 728), -- Hip Hop  ->  Digicore
  (1182, 736), -- Hip Hop  ->  Dirty South
  (1182, 739), -- Hip Hop  ->  Disco Rap
  (1182, 770), -- Hip Hop  ->  Drill
  (1182, 778), -- Hip Hop  ->  Drumless
  (1182, 839), -- Hip Hop  ->  Emo Rap
  (1182, 875), -- Hip Hop  ->  Experimental Hip Hop
  (1182, 1011), -- Hip Hop  ->  G-Funk
  (1182, 1045), -- Hip Hop  ->  Genge
  (1182, 1147), -- Hip Hop  ->  Hardcore Hip Hop
  (1182, 1186), -- Hip Hop  ->  Hipco
  (1182, 1187), -- Hip Hop  ->  Hiplife
  (1182, 1208), -- Hip Hop  ->  Houston Sound
  (1182, 1221), -- Hip Hop  ->  Hyphy
  (1182, 1266), -- Hip Hop  ->  Instrumental Hip Hop
  (1182, 1315), -- Hip Hop  ->  Jazz Rap
  (1182, 1320), -- Hip Hop  ->  Jerk
  (1182, 1323), -- Hip Hop  ->  Jersey Club Rap
  (1182, 1332), -- Hip Hop  ->  Jigg
  (1182, 1339), -- Hip Hop  ->  Jook
  (1182, 1463), -- Hip Hop  ->  Latin Rap
  (1182, 1489), -- Hip Hop  ->  Lo-Fi Hip Hop
  (1182, 1500), -- Hip Hop  ->  Lowend
  (1182, 1613), -- Hip Hop  ->  Miami Bass
  (1182, 1642), -- Hip Hop  ->  Mobb Music
  (1182, 1673), -- Hip Hop  ->  Motswako
  (1182, 1753), -- Hip Hop  ->  Nerdcore Hip Hop
  (1182, 1755), -- Hip Hop  ->  Nervous Music
  (1182, 1947), -- Hip Hop  ->  Philly Club Rap
  (1182, 1980), -- Hip Hop  ->  Political Hip Hop
  (1182, 1996), -- Hip Hop  ->  Pop Rap
  (1182, 2116), -- Hip Hop  ->  Ratchet
  (1182, 2216), -- Hip Hop  ->  Samba Rap
  (1182, 2312), -- Hip Hop  ->  Sigilkore
  (1182, 2349), -- Hip Hop  ->  Snap
  (1182, 2433), -- Hip Hop  ->  Stoner Rap
  (1182, 2596), -- Hip Hop  ->  Trap
  (1182, 2601), -- Hip Hop  ->  Trap shaabi
  (1182, 2640), -- Hip Hop  ->  Turntablism
  (1188, 207), -- Hispanic American Folk Music  ->  Bambuco
  (1188, 312), -- Hispanic American Folk Music  ->  Bomba
  (1188, 415), -- Hispanic American Folk Music  ->  Candombe
  (1188, 421), -- Hispanic American Folk Music  ->  Canto a lo poeta
  (1188, 450), -- Hispanic American Folk Music  ->  Carranga
  (1188, 468), -- Hispanic American Folk Music  ->  Chacarera
  (1188, 471), -- Hispanic American Folk Music  ->  Chamamé
  (1188, 474), -- Hispanic American Folk Music  ->  Chamarrita rioplatense
  (1188, 631), -- Hispanic American Folk Music  ->  Cueca
  (1188, 1210), -- Hispanic American Folk Music  ->  Huayno
  (1188, 1331), -- Hispanic American Folk Music  ->  Jibaro
  (1188, 1340), -- Hispanic American Folk Music  ->  Joropo
  (1188, 1525), -- Hispanic American Folk Music  ->  Malagueña venezolana
  (1188, 1610), -- Hispanic American Folk Music  ->  Mexican Folk Music
  (1188, 1626), -- Hispanic American Folk Music  ->  Milonga
  (1188, 1682), -- Hispanic American Folk Music  ->  Muliza
  (1188, 1709), -- Hispanic American Folk Music  ->  Música llanera
  (1188, 1970), -- Hispanic American Folk Music  ->  Plena
  (1188, 2244), -- Hispanic American Folk Music  ->  Saya
  (1188, 2487), -- Hispanic American Folk Music  ->  Tamborito
  (1188, 2496), -- Hispanic American Folk Music  ->  Taquirari
  (1188, 2563), -- Hispanic American Folk Music  ->  Tonada chilena
  (1188, 2779), -- Hispanic American Folk Music  ->  Yaraví
  (1188, 2794), -- Hispanic American Folk Music  ->  Zamacueca
  (1188, 2795), -- Hispanic American Folk Music  ->  Zamba
  (1189, 38), -- Hispanic American Music  ->  Afro-Cuban Jazz
  (1189, 123), -- Hispanic American Music  ->  Argentine Music
  (1189, 166), -- Hispanic American Music  ->  Avanzada
  (1189, 183), -- Hispanic American Music  ->  Bailecito
  (1189, 306), -- Hispanic American Music  ->  Bolero
  (1189, 314), -- Hispanic American Music  ->  Boogaloo
  (1189, 387), -- Hispanic American Music  ->  Bullerengue
  (1189, 440), -- Hispanic American Music  ->  Caporal
  (1189, 447), -- Hispanic American Music  ->  Carnaval cruceño
  (1189, 479), -- Hispanic American Music  ->  Champeta
  (1189, 506), -- Hispanic American Music  ->  Chilean Music
  (1189, 535), -- Hispanic American Music  ->  Chuntunqui romántico
  (1189, 580), -- Hispanic American Music  ->  Conjunto andino
  (1189, 628), -- Hispanic American Music  ->  Cuban Music
  (1189, 633), -- Hispanic American Music  ->  Cumbia
  (1189, 651), -- Hispanic American Music  ->  Currulao
  (1189, 752), -- Hispanic American Music  ->  Dominican Music
  (1189, 1018), -- Hispanic American Music  ->  Gaita zuliana
  (1189, 1104), -- Hispanic American Music  ->  Guarania
  (1189, 1188), -- Hispanic American Music  ->  Hispanic American Folk Music
  (1189, 1454), -- Hispanic American Music  ->  Latin Alternative
  (1189, 1455), -- Hispanic American Music  ->  Latin American Classical Music
  (1189, 1456), -- Hispanic American Music  ->  Latin Disco
  (1189, 1457), -- Hispanic American Music  ->  Latin Electronic
  (1189, 1459), -- Hispanic American Music  ->  Latin Funk
  (1189, 1462), -- Hispanic American Music  ->  Latin Pop
  (1189, 1464), -- Hispanic American Music  ->  Latin Rock
  (1189, 1465), -- Hispanic American Music  ->  Latin Soul
  (1189, 1611), -- Hispanic American Music  ->  Mexican Music
  (1189, 1772), -- Hispanic American Music  ->  New Mexico Music
  (1189, 1852), -- Hispanic American Music  ->  Nueva canción latinoamericana
  (1189, 1877), -- Hispanic American Music  ->  Onda nueva
  (1189, 1930), -- Hispanic American Music  ->  Pasillo
  (1189, 1942), -- Hispanic American Music  ->  Peruvian Music
  (1189, 1982), -- Hispanic American Music  ->  Polka paraguaya
  (1189, 2006), -- Hispanic American Music  ->  Porro
  (1189, 2076), -- Hispanic American Music  ->  Purísima
  (1189, 2128), -- Hispanic American Music  ->  Reggaetón
  (1189, 2138), -- Hispanic American Music  ->  Rhumba
  (1189, 2144), -- Hispanic American Music  ->  Rioplatense Music
  (1189, 2156), -- Hispanic American Music  ->  Rock andino
  (1189, 2206), -- Hispanic American Music  ->  Salsa
  (1189, 2358), -- Hispanic American Music  ->  Son de pascua
  (1189, 2363), -- Hispanic American Music  ->  Son nica
  (1189, 2486), -- Hispanic American Music  ->  Tamborera
  (1189, 2613), -- Hispanic American Music  ->  Tropicanibalismo
  (1189, 2687), -- Hispanic American Music  ->  Vallenato
  (1189, 2689), -- Hispanic American Music  ->  Vals venezolano
  (1189, 2773), -- Hispanic American Music  ->  Xuc
  (1190, 414), -- Hispanic Music  ->  Canción melódica
  (1190, 1189), -- Hispanic Music  ->  Hispanic American Music
  (1190, 1683), -- Hispanic Music  ->  Murga
  (1190, 1849), -- Hispanic Music  ->  Nueva canción
  (1190, 1945), -- Hispanic Music  ->  Philippine Rondalla
  (1190, 2173), -- Hispanic Music  ->  Romance
  (1190, 2408), -- Hispanic Music  ->  Spanish Music
  (1195, 449), -- Holiday Music  ->  Carols
  (1195, 533), -- Holiday Music  ->  Christmas Music
  (1195, 1122), -- Holiday Music  ->  Halloween Music
  (1195, 1559), -- Holiday Music  ->  Marchinha
  (1195, 2220), -- Holiday Music  ->  Samba-enredo
  (1195, 2560), -- Holiday Music  ->  Toada de Boi
  (1199, 187), -- Honky Tonk  ->  Bakersfield Sound
  (1199, 2620), -- Honky Tonk  ->  Truck Driving Country
  (1207, 17), -- House  ->  Acid House
  (1207, 36), -- House  ->  Afro House
  (1207, 78), -- House  ->  Amapiano
  (1207, 84), -- House  ->  Ambient House
  (1207, 200), -- House  ->  Ballroom
  (1207, 203), -- House  ->  Baltimore Club
  (1207, 227), -- House  ->  Bass House
  (1207, 228), -- House  ->  Bassline
  (1207, 274), -- House  ->  Big Room House
  (1207, 330), -- House  ->  Brazilian Bass
  (1207, 378), -- House  ->  Bubbling House
  (1207, 480), -- House  ->  Changa tuki
  (1207, 496), -- House  ->  Chicago Hard House
  (1207, 497), -- House  ->  Chicago House
  (1207, 707), -- House  ->  Deep House
  (1207, 742), -- House  ->  Diva House
  (1207, 821), -- House  ->  Electro House
  (1207, 835), -- House  ->  Eletrofunk
  (1207, 860), -- House  ->  Euro House
  (1207, 891), -- House  ->  Festival Progressive House
  (1207, 962), -- House  ->  French House
  (1207, 997), -- House  ->  Funky House
  (1207, 1003), -- House  ->  Future Funk
  (1207, 1005), -- House  ->  Future House
  (1207, 1012), -- House  ->  G-House
  (1207, 1036), -- House  ->  Garage House
  (1207, 1052), -- House  ->  Ghetto House
  (1207, 1184), -- House  ->  Hip House
  (1207, 1282), -- House  ->  Italo House
  (1207, 1291), -- House  ->  Jackin' House
  (1207, 1438), -- House  ->  Kwaito
  (1207, 1460), -- House  ->  Latin House
  (1207, 1595), -- House  ->  Melodic House
  (1207, 1615), -- House  ->  Microhouse
  (1207, 1891), -- House  ->  Organic House
  (1207, 1903), -- House  ->  Outsider House
  (1207, 1952), -- House  ->  Phonk House
  (1207, 2045), -- House  ->  Progressive House
  (1207, 2178), -- House  ->  Romanian Popcorn
  (1207, 2411), -- House  ->  Speed Garage
  (1207, 2440), -- House  ->  Stutter House
  (1207, 2510), -- House  ->  Tech House
  (1207, 2608), -- House  ->  Tribal House
  (1207, 2611), -- House  ->  Tropical House
  (1207, 2657), -- House  ->  UK Hard House
  (1207, 2660), -- House  ->  UK Jackin'
  (1207, 2711), -- House  ->  Vinahouse
  (1210, 311), -- Huayno  ->  Bolivian Huayño
  (1210, 448), -- Huayno  ->  Carnavalito
  (1210, 513), -- Huayno  ->  Chimaychi
  (1210, 2847), -- Huayno  ->  Chuscada
  (1210, 2854), -- Huayno  ->  Huayno con Arpa
  (1212, 625), -- Hungarian Folk Music  ->  Csárdás
  (1212, 1517), -- Hungarian Folk Music  ->  Magyar nóta
  (1212, 2078), -- Hungarian Folk Music  ->  Pásztordal
  (1216, 268), -- Hymn  ->  Bhajan
  (1216, 1467), -- Hymn  ->  Lauda
  (1216, 2076), -- Hymn  ->  Purísima
  (1216, 2291), -- Hymn  ->  Shape Note Singing
  (1216, 2842), -- Hymn  ->  Gospel Hymn
  (1221, 1321), -- Hyphy  ->  Jerk Rap
  (1225, 226), -- Iberian Music  ->  Basque Folk Music
  (1225, 453), -- Iberian Music  ->  Catalan Folk Music
  (1225, 870), -- Iberian Music  ->  Euskal kantagintza berria
  (1225, 884), -- Iberian Music  ->  Fandango
  (1225, 1833), -- Iberian Music  ->  Nova cançó
  (1225, 2008), -- Iberian Music  ->  Portuguese Music
  (1225, 2408), -- Iberian Music  ->  Spanish Music
  (1225, 2710), -- Iberian Music  ->  Villancico
  (1228, 771), -- IDM  ->  Drill and Bass
  (1230, 1871), -- Igbo Music  ->  Ogene Music
  (1237, 305), -- Indian Pop  ->  Bhojpuri Pop
  (1238, 2431), -- Indie Folk  ->  Stomp and Holler
  (1239, 252), -- Indie Pop  ->  Bedroom Pop
  (1239, 398), -- Indie Pop  ->  C86
  (1239, 478), -- Indie Pop  ->  Chamber Pop
  (1239, 1731), -- Indie Pop  ->  Neo-Acoustic
  (1239, 2567), -- Indie Pop  ->  Tontipop
  (1239, 2644), -- Indie Pop  ->  Twee Pop
  (1241, 180), -- Indie Rock  ->  Baggy
  (1241, 398), -- Indie Rock  ->  C86
  (1241, 751), -- Indie Rock  ->  Dolewave
  (1241, 790), -- Indie Rock  ->  Dunedin Sound
  (1241, 1040), -- Indie Rock  ->  Garage Rock Revival
  (1241, 1239), -- Indie Rock  ->  Indie Pop
  (1241, 1243), -- Indie Rock  ->  Indie Surf
  (1241, 1570), -- Indie Rock  ->  Math Pop
  (1241, 1622), -- Indie Rock  ->  Midwest Emo
  (1241, 1780), -- Indie Rock  ->  New Rave
  (1241, 1810), -- Indie Rock  ->  Noise Pop
  (1241, 2021), -- Indie Rock  ->  Post-Punk Revival
  (1241, 2334), -- Indie Rock  ->  Slacker Rock
  (1241, 2343), -- Indie Rock  ->  Slowcore
  (1244, 511), -- Indietronica  ->  Chillwave
  (1244, 1064), -- Indietronica  ->  Glitch Pop
  (1244, 1955), -- Indietronica  ->  Picopop
  (1245, 1042), -- Indigenous American Music  ->  Garifuna Folk Music
  (1245, 1246), -- Indigenous American Music  ->  Indigenous American Traditional Music
  (1245, 1247), -- Indigenous American Music  ->  Indigenous Andean Music
  (1245, 1249), -- Indigenous American Music  ->  Indigenous North American Music
  (1245, 1606), -- Indigenous American Music  ->  Mesoamerican Music
  (1246, 150), -- Indigenous American Traditional Music  ->  Athabaskan Fiddling
  (1246, 1054), -- Indigenous American Traditional Music  ->  Ghost Dance Song
  (1246, 1270), -- Indigenous American Traditional Music  ->  Inuit Vocal Games
  (1246, 1296), -- Indigenous American Traditional Music  ->  James Bay Fiddling
  (1246, 1552), -- Indigenous American Traditional Music  ->  Mapuche Folk Music
  (1246, 2030), -- Indigenous American Traditional Music  ->  Powwow Music
  (1246, 2089), -- Indigenous American Traditional Music  ->  Rabbit Song
  (1246, 2564), -- Indigenous American Traditional Music  ->  Tonada potosina
  (1246, 2667), -- Indigenous American Traditional Music  ->  Unakesa
  (1247, 181), -- Indigenous Andean Music  ->  Baguala
  (1247, 1133), -- Indigenous Andean Music  ->  Harawi
  (1247, 1209), -- Indigenous Andean Music  ->  Huaylarsh
  (1247, 1210), -- Indigenous Andean Music  ->  Huayno
  (1247, 1665), -- Indigenous Andean Music  ->  Morenada
  (1247, 2564), -- Indigenous Andean Music  ->  Tonada potosina
  (1248, 745), -- Indigenous Australian Traditional Music  ->  Djanba
  (1248, 2733), -- Indigenous Australian Traditional Music  ->  Wangga
  (1249, 150), -- Indigenous North American Music  ->  Athabaskan Fiddling
  (1249, 1054), -- Indigenous North American Music  ->  Ghost Dance Song
  (1249, 1269), -- Indigenous North American Music  ->  Inuit Music
  (1249, 1296), -- Indigenous North American Music  ->  James Bay Fiddling
  (1249, 1703), -- Indigenous North American Music  ->  Métis Music
  (1249, 1725), -- Indigenous North American Music  ->  Navajo Music
  (1249, 1863), -- Indigenous North American Music  ->  O'odham Music
  (1249, 2030), -- Indigenous North American Music  ->  Powwow Music
  (1249, 2067), -- Indigenous North American Music  ->  Pueblo Music
  (1249, 2089), -- Indigenous North American Music  ->  Rabbit Song
  (1252, 185), -- Indo-Caribbean Music  ->  Baithak gana
  (1252, 536), -- Indo-Caribbean Music  ->  Chutney
  (1252, 2503), -- Indo-Caribbean Music  ->  Tassa
  (1253, 191), -- Indonesian Music  ->  Balinese Music
  (1253, 229), -- Indonesian Music  ->  Batak Music
  (1253, 669), -- Indonesian Music  ->  Dangdut
  (1253, 1021), -- Indonesian Music  ->  Gambang kromong
  (1253, 1306), -- Indonesian Music  ->  Javanese Music
  (1253, 1364), -- Indonesian Music  ->  Kakawin
  (1253, 1389), -- Indonesian Music  ->  Keroncong
  (1253, 1629), -- Indonesian Music  ->  Minangkabau Music
  (1253, 1895), -- Indonesian Music  ->  Orkes gambus
  (1253, 2083), -- Indonesian Music  ->  Qasidah modern
  (1253, 2444), -- Indonesian Music  ->  Sundanese Music
  (1253, 2493), -- Indonesian Music  ->  Tanjidor
  (1255, 2023), -- Industrial  ->  Power Electronics
  (1256, 1255), -- Industrial & Noise  ->  Industrial
  (1256, 1809), -- Industrial & Noise  ->  Noise
  (1256, 2017), -- Industrial & Noise  ->  Post-Industrial
  (1260, 653), -- Industrial Metal  ->  Cyber Metal
  (1260, 1756), -- Industrial Metal  ->  Neue Deutsche Härte
  (1261, 1510), -- Industrial Rock  ->  Machine Rock
  (1262, 281), -- Industrial Techno  ->  Birmingham Sound
  (1266, 2112), -- Instrumental Hip Hop  ->  Rare Phonk
  (1269, 1270), -- Inuit Music  ->  Inuit Vocal Games
  (1269, 2558), -- Inuit Music  ->  Tivaner inngernerlu
  (1269, 2650), -- Inuit Music  ->  Uaajeerneq
  (1273, 2259), -- Irish Folk Music  ->  Sean-nós
  (1276, 1056), -- Islamic Religious Music & Recitation  ->  Ginan
  (1276, 1333), -- Islamic Religious Music & Recitation  ->  Jilala Music
  (1276, 1512), -- Islamic Religious Music & Recitation  ->  Maddahi
  (1276, 1551), -- Islamic Religious Music & Recitation  ->  Mappila
  (1276, 1569), -- Islamic Religious Music & Recitation  ->  Mataali
  (1276, 1720), -- Islamic Religious Music & Recitation  ->  Nasheed
  (1276, 2108), -- Islamic Religious Music & Recitation  ->  Rapai dabõih
  (1276, 2635), -- Islamic Religious Music & Recitation  ->  Turkish Mevlevi Music
  (1279, 424), -- Italian Folk Music  ->  Canto degli Alpini
  (1279, 433), -- Italian Folk Music  ->  Canzone napoletana
  (1279, 1482), -- Italian Folk Music  ->  Liscio
  (1279, 2239), -- Italian Folk Music  ->  Sardinian Folk Music
  (1279, 2435), -- Italian Folk Music  ->  Stornello
  (1279, 2499), -- Italian Folk Music  ->  Tarantella
  (1279, 2590), -- Italian Folk Music  ->  Trallalero
  (1280, 422), -- Italian Music  ->  Canto beneventano
  (1280, 432), -- Italian Music  ->  Canzone d'autore
  (1280, 1279), -- Italian Music  ->  Italian Folk Music
  (1280, 1467), -- Italian Music  ->  Lauda
  (1280, 1874), -- Italian Music  ->  Old Roman Chant
  (1280, 1881), -- Italian Music  ->  Opera buffa
  (1280, 1882), -- Italian Music  ->  Opera semiseria
  (1280, 1883), -- Italian Music  ->  Opera seria
  (1283, 434), -- Italo Pop  ->  Canzone neomelodica
  (1284, 2404), -- Italo-Disco  ->  Spacesynth
  (1287, 1002), -- J-core  ->  Future Core
  (1287, 2833), -- J-core  ->  Hard Renaissance
  (1289, 55), -- J-Pop  ->  Akishibu-kei
  (1289, 716), -- J-Pop  ->  Denpa
  (1289, 2728), -- J-Pop  ->  Wa Euro
  (1289, 2776), -- J-Pop  ->  Yakousei
  (1289, 2841), -- J-Pop  ->  VTuber Music
  (1293, 1297), -- Jam Band  ->  Jamgrass
  (1293, 1486), -- Jam Band  ->  Livetronica
  (1294, 667), -- Jamaican Music  ->  Dancehall
  (1294, 1295), -- Jamaican Music  ->  Jamaican Ska
  (1294, 1432), -- Jamaican Music  ->  Kumina
  (1294, 1600), -- Jamaican Music  ->  Mento
  (1294, 1861), -- Jamaican Music  ->  Nyahbinghi
  (1294, 2125), -- Jamaican Music  ->  Reggae
  (1294, 2170), -- Jamaican Music  ->  Rocksteady
  (1298, 398), -- Jangle Pop  ->  C86
  (1298, 751), -- Jangle Pop  ->  Dolewave
  (1298, 1731), -- Jangle Pop  ->  Neo-Acoustic
  (1298, 1914), -- Jangle Pop  ->  Paisley Underground
  (1299, 1015), -- Japanese Classical Music  ->  Gagaku
  (1299, 1169), -- Japanese Classical Music  ->  Heikyoku
  (1299, 1201), -- Japanese Classical Music  ->  Honkyoku
  (1299, 1336), -- Japanese Classical Music  ->  Jiuta
  (1299, 1353), -- Japanese Classical Music  ->  Jōruri
  (1299, 1587), -- Japanese Classical Music  ->  Meiji shinkyoku
  (1299, 1714), -- Japanese Classical Music  ->  Nagauta
  (1299, 1807), -- Japanese Classical Music  ->  Noh
  (1299, 2307), -- Japanese Classical Music  ->  Shōmyō
  (1299, 2475), -- Japanese Classical Music  ->  Sōkyoku
  (1300, 1169), -- Japanese Folk Music  ->  Heikyoku
  (1300, 1361), -- Japanese Folk Music  ->  Kagura
  (1300, 1419), -- Japanese Folk Music  ->  Kouta
  (1300, 1628), -- Japanese Folk Music  ->  Min'yō
  (1300, 1878), -- Japanese Folk Music  ->  Ondō
  (1300, 2197), -- Japanese Folk Music  ->  Rōkyoku
  (1300, 2479), -- Japanese Folk Music  ->  Taiko
  (1300, 2624), -- Japanese Folk Music  ->  Tsugaru Shamisen
  (1303, 72), -- Japanese Idol  ->  Alternative Idol
  (1304, 834), -- Japanese Music  ->  Eleki
  (1304, 847), -- Japanese Music  ->  Enka
  (1304, 1299), -- Japanese Music  ->  Japanese Classical Music
  (1304, 1300), -- Japanese Music  ->  Japanese Folk Music
  (1304, 2196), -- Japanese Music  ->  Ryūkōka
  (1305, 1031), -- Javanese Gamelan  ->  Gamelan sekaten
  (1305, 2354), -- Javanese Gamelan  ->  Solonese Gamelan
  (1306, 215), -- Javanese Music  ->  Bantengan
  (1306, 409), -- Javanese Music  ->  Campursari
  (1306, 670), -- Javanese Music  ->  Dangdut koplo
  (1306, 1305), -- Javanese Music  ->  Javanese Gamelan
  (1306, 1427), -- Javanese Music  ->  Kuda kepang
  (1306, 1452), -- Javanese Music  ->  Langgam Jawa
  (1308, 40), -- Jazz  ->  Afro-Jazz
  (1308, 119), -- Jazz  ->  Arabic Jazz
  (1308, 163), -- Jazz  ->  Avant-Garde Jazz
  (1308, 250), -- Jazz  ->  Bebop
  (1308, 271), -- Jazz  ->  Big Band
  (1308, 355), -- Jazz  ->  British Dance Band
  (1308, 384), -- Jazz  ->  Bulawayo Jazz
  (1308, 437), -- Jazz  ->  Cape Jazz
  (1308, 451), -- Jazz  ->  Cartoon Music
  (1308, 476), -- Jazz  ->  Chamber Jazz
  (1308, 587), -- Jazz  ->  Cool Jazz
  (1308, 614), -- Jazz  ->  Crime Jazz
  (1308, 683), -- Jazz  ->  Dark Jazz
  (1308, 744), -- Jazz  ->  Dixieland
  (1308, 813), -- Jazz  ->  ECM Style Jazz
  (1308, 856), -- Jazz  ->  Ethio-Jazz
  (1308, 910), -- Jazz  ->  Flamenco Jazz
  (1308, 1135), -- Jazz  ->  Hard Bop
  (1308, 1251), -- Jazz  ->  Indo Jazz
  (1308, 1309), -- Jazz  ->  Jazz Fusion
  (1308, 1311), -- Jazz  ->  Jazz manouche
  (1308, 1313), -- Jazz  ->  Jazz Poetry
  (1308, 1316), -- Jazz  ->  Jazz-Funk
  (1308, 1426), -- Jazz  ->  Kréyol djaz
  (1308, 1461), -- Jazz  ->  Latin Jazz
  (1308, 1554), -- Jazz  ->  Marabi
  (1308, 1646), -- Jazz  ->  Modal Jazz
  (1308, 1732), -- Jazz  ->  Neo-Bop
  (1308, 1925), -- Jazz  ->  Paramaribop
  (1308, 2012), -- Jazz  ->  Post-Bop
  (1308, 2347), -- Jazz  ->  Smooth Jazz
  (1308, 2373), -- Jazz  ->  Soul Jazz
  (1308, 2417), -- Jazz  ->  Spiritual Jazz
  (1308, 2422), -- Jazz  ->  Spy Music
  (1308, 2438), -- Jazz  ->  Stride
  (1308, 2458), -- Jazz  ->  Sweet Jazz
  (1308, 2459), -- Jazz  ->  Swing
  (1308, 2545), -- Jazz  ->  Third Stream
  (1308, 2718), -- Jazz  ->  Vocal Jazz
  (1308, 2747), -- Jazz  ->  West Coast Jazz
  (1316, 951), -- Jazz-Funk  ->  Free Funk
  (1319, 1017), -- Jeong-ak  ->  Gagok
  (1323, 1324), -- Jersey Club Rap  ->  Jersey Drill
  (1328, 101), -- Jewish Liturgical Music  ->  Ancient Levitical Music
  (1328, 492), -- Jewish Liturgical Music  ->  Chazzanut
  (1328, 1423), -- Jewish Liturgical Music  ->  Kriyat haTorah
  (1328, 1967), -- Jewish Liturgical Music  ->  Piyyut
  (1329, 141), -- Jewish Music  ->  Ashkenazi Music
  (1329, 1160), -- Jewish Music  ->  Hasidic Music
  (1329, 1328), -- Jewish Music  ->  Jewish Liturgical Music
  (1329, 1696), -- Jewish Music  ->  Muzika mizrahit
  (1329, 1697), -- Jewish Music  ->  Muzika yehudit mekorit
  (1329, 1894), -- Jewish Music  ->  Oriental Jewish Music
  (1329, 1897), -- Jewish Music  ->  Orthodox Pop
  (1329, 2269), -- Jewish Music  ->  Sephardic Music
  (1338, 1989), -- Jongo  ->  Ponto de umbanda
  (1348, 2098), -- Jungle  ->  Ragga Jungle
  (1354, 2268), -- K-Pop  ->  Semi-Trot
  (1382, 1002), -- Kawaii Future Bass  ->  Future Core
  (1384, 1229), -- Kayōkyoku  ->  Idol kayō
  (1384, 1658), -- Kayōkyoku  ->  Mood kayō
  (1384, 2516), -- Kayōkyoku  ->  Techno kayō
  (1389, 541), -- Keroncong  ->  Cilokaq
  (1389, 1452), -- Keroncong  ->  Langgam Jawa
  (1393, 170), -- Khaliji Music  ->  Ayyalah
  (1393, 900), -- Khaliji Music  ->  Fijiri
  (1393, 1488), -- Khaliji Music  ->  Liwa
  (1393, 1846), -- Khaliji Music  ->  Nuban
  (1393, 2231), -- Khaliji Music  ->  Samri
  (1393, 2243), -- Khaliji Music  ->  Sawt
  (1393, 2294), -- Khaliji Music  ->  Shehhi Music
  (1393, 2298), -- Khaliji Music  ->  Shilla
  (1396, 408), -- Khmer Music  ->  Cambodian Pop
  (1396, 1375), -- Khmer Music  ->  Kantruem
  (1396, 1395), -- Khmer Music  ->  Khmer Folk Music
  (1396, 1961), -- Khmer Music  ->  Pinpeat
  (1402, 2286), -- Kirtan  ->  Shabad kirtan
  (1404, 2501), -- Kizomba  ->  Tarraxinha
  (1413, 1893), -- Korean Ballad  ->  Oriental Ballad
  (1414, 7), -- Korean Classical Music  ->  Aak
  (1414, 668), -- Korean Classical Music  ->  Dang-ak
  (1414, 1214), -- Korean Classical Music  ->  Hyang-ak
  (1414, 1319), -- Korean Classical Music  ->  Jeong-ak
  (1415, 1679), -- Korean Folk Music  ->  Muak
  (1415, 1922), -- Korean Folk Music  ->  Pansori
  (1415, 2068), -- Korean Folk Music  ->  Pungmul
  (1415, 2234), -- Korean Folk Music  ->  Sanjo
  (1415, 2313), -- Korean Folk Music  ->  Sinawi
  (1416, 265), -- Korean Music  ->  Beompae
  (1416, 482), -- Korean Music  ->  Changjak gugak
  (1416, 999), -- Korean Music  ->  Fusion Gugak
  (1416, 1414), -- Korean Music  ->  Korean Classical Music
  (1416, 1415), -- Korean Music  ->  Korean Folk Music
  (1416, 1417), -- Korean Music  ->  Korean Revolutionary Opera
  (1416, 1893), -- Korean Music  ->  Oriental Ballad
  (1416, 2616), -- Korean Music  ->  Trot
  (1424, 64), -- Kru Music  ->  Alloukou
  (1424, 1918), -- Kru Music  ->  Palm Wine Music
  (1424, 2808), -- Kru Music  ->  Ziglibithy
  (1428, 230), -- Kuduro  ->  Batida
  (1438, 174), -- Kwaito  ->  Bacardi
  (1449, 849), -- Laika  ->  Entechna laika
  (1449, 1649), -- Laika  ->  Modern Laika
  (1449, 2329), -- Laika  ->  Skiladika
  (1450, 1108), -- Lambada  ->  Guitarrada
  (1454, 1853), -- Latin Alternative  ->  Nueva cumbia chilena
  (1457, 480), -- Latin Electronic  ->  Changa tuki
  (1457, 729), -- Latin Electronic  ->  Digital Cumbia
  (1457, 822), -- Latin Electronic  ->  Electro latino
  (1457, 833), -- Latin Electronic  ->  Electrotango
  (1457, 1819), -- Latin Electronic  ->  Nortec
  (1457, 2607), -- Latin Electronic  ->  Tribal Guarachero
  (1461, 38), -- Latin Jazz  ->  Afro-Cuban Jazz
  (1461, 2222), -- Latin Jazz  ->  Samba-jazz
  (1462, 642), -- Latin Pop  ->  Cumbia pop
  (1462, 2615), -- Latin Pop  ->  Tropipop
  (1463, 502), -- Latin Rap  ->  Chicano Rap
  (1473, 781), -- Levantine Arabic Music  ->  Druze Music
  (1473, 1713), -- Levantine Arabic Music  ->  Mūsīqā lubnāniyya
  (1480, 2227), -- Liquid Drum and Bass  ->  Sambass
  (1484, 2452), -- Lithuanian Folk Music  ->  Sutartinės
  (1496, 404), -- Louisiana Music  ->  Cajun Music
  (1496, 1775), -- Louisiana Music  ->  New Orleans Brass Band
  (1496, 1776), -- Louisiana Music  ->  New Orleans R&B
  (1496, 2453), -- Louisiana Music  ->  Swamp Blues
  (1496, 2454), -- Louisiana Music  ->  Swamp Pop
  (1496, 2818), -- Louisiana Music  ->  Zydeco
  (1502, 1479), -- Luk krung  ->  Lilat
  (1504, 232), -- Lullabies  ->  Batonebi Songs
  (1509, 2823), -- Macedonian Folk Music  ->  Čalgija
  (1512, 2305), -- Maddahi  ->  Shoor
  (1516, 53), -- Maghrebi Music  ->  Aita
  (1516, 62), -- Maghrebi Music  ->  Algerian Chaabi
  (1516, 104), -- Maghrebi Music  ->  Andalusian Classical Music
  (1516, 214), -- Maghrebi Music  ->  Banga
  (1516, 1065), -- Maghrebi Music  ->  Gnawa
  (1516, 1333), -- Maghrebi Music  ->  Jilala Music
  (1516, 1531), -- Maghrebi Music  ->  Malhun
  (1516, 1667), -- Maghrebi Music  ->  Moroccan Chaabi
  (1516, 2120), -- Maghrebi Music  ->  Raï
  (1524, 1368), -- Malagasy Music  ->  Kalon'ny fahiny
  (1524, 1523), -- Malagasy Music  ->  Malagasy Folk Music
  (1524, 2205), -- Malagasy Music  ->  Salegy
  (1524, 2622), -- Malagasy Music  ->  Tsapiky
  (1526, 1528), -- Malay Classical Music  ->  Malay Gamelan
  (1529, 733), -- Malay Music  ->  Dikir barat
  (1529, 753), -- Malay Music  ->  Dondang sayang
  (1529, 1526), -- Malay Music  ->  Malay Classical Music
  (1529, 1527), -- Malay Music  ->  Malay Folk Music
  (1529, 2002), -- Malay Music  ->  Pop Yeh-Yeh
  (1529, 2159), -- Malay Music  ->  Rock Kapak
  (1530, 1551), -- Malayali Folk Music  ->  Mappila
  (1534, 1535), -- Maloya  ->  Maloya électronique
  (1534, 1536), -- Maloya  ->  Maloya élektrik
  (1534, 2585), -- Maloya  ->  Traditional Maloya
  (1547, 2550), -- Mantra  ->  Tibetan Buddhist Chant
  (1547, 2699), -- Mantra  ->  Vedic Chant
  (1553, 117), -- Maqāmic Music  ->  Arabic Classical Music
  (1553, 171), -- Maqāmic Music  ->  Azerbaijani Mugham
  (1553, 240), -- Maqāmic Music  ->  Bayawan
  (1553, 1938), -- Maqāmic Music  ->  Persian Classical Music
  (1553, 2292), -- Maqāmic Music  ->  Shashmaqam
  (1553, 2443), -- Maqāmic Music  ->  Sufiana kalam
  (1553, 2633), -- Maqāmic Music  ->  Turkish Classical Music
  (1553, 2645), -- Maqāmic Music  ->  Twelve Muqam
  (1554, 1440), -- Marabi  ->  Kwela
  (1554, 1578), -- Marabi  ->  Mbaqanga
  (1556, 1469), -- Marathi Folk Music  ->  Lavani
  (1557, 545), -- March  ->  Circus March
  (1557, 749), -- March  ->  Dobrado
  (1557, 978), -- March  ->  Funeral March
  (1557, 1707), -- March  ->  Música festera
  (1558, 262), -- Marching Band  ->  Beni
  (1558, 776), -- Marching Band  ->  Drum and Bugle Corps
  (1558, 779), -- Marching Band  ->  Drumline
  (1558, 898), -- Marching Band  ->  Fife and Drum Corps
  (1558, 1106), -- Marching Band  ->  Guggenmusik
  (1558, 1937), -- Marching Band  ->  Pep Band
  (1558, 1963), -- Marching Band  ->  Pipe Band
  (1568, 2134), -- Mass  ->  Requiem
  (1571, 1570), -- Math Rock  ->  Math Pop
  (1584, 132), -- Medieval Classical Music  ->  Ars antiqua
  (1584, 133), -- Medieval Classical Music  ->  Ars nova
  (1584, 134), -- Medieval Classical Music  ->  Ars subtilior
  (1584, 586), -- Medieval Classical Music  ->  Contenance angloise
  (1584, 1585), -- Medieval Classical Music  ->  Medieval Lyric Poetry
  (1584, 1969), -- Medieval Classical Music  ->  Plainsong
  (1588, 899), -- Melanesian Music  ->  Fijian Music
  (1588, 1370), -- Melanesian Music  ->  Kaneka
  (1588, 1492), -- Melanesian Music  ->  Lokal musik
  (1588, 1924), -- Melanesian Music  ->  Papuan Folk Music
  (1588, 2562), -- Melanesian Music  ->  Tolai Rock
  (1592, 1078), -- Melodic Death Metal  ->  Gothenburg Sound
  (1598, 791), -- Memphis Rap  ->  Dungeon Rap
  (1598, 1951), -- Memphis Rap  ->  Phonk
  (1602, 1539), -- Merengue  ->  Mambo urbano
  (1602, 1601), -- Merengue  ->  Merecumbé
  (1602, 1603), -- Merengue  ->  Merengue típico
  (1602, 1604), -- Merengue  ->  Merenhouse
  (1602, 2523), -- Merengue  ->  Tecnomerengue
  (1606, 1574), -- Mesoamerican Music  ->  Maya Music
  (1606, 1716), -- Mesoamerican Music  ->  Nahua Music
  (1606, 1965), -- Mesoamerican Music  ->  Pirekua
  (1608, 73), -- Metal  ->  Alternative Metal
  (1608, 164), -- Metal  ->  Avant-Garde Metal
  (1608, 288), -- Metal  ->  Black Metal
  (1608, 696), -- Metal  ->  Death Metal
  (1608, 746), -- Metal  ->  Djent
  (1608, 757), -- Metal  ->  Doom Metal
  (1608, 774), -- Metal  ->  Drone Metal
  (1608, 922), -- Metal  ->  Folk Metal
  (1608, 1080), -- Metal  ->  Gothic Metal
  (1608, 1092), -- Metal  ->  Grindcore
  (1608, 1094), -- Metal  ->  Groove Metal
  (1608, 1167), -- Metal  ->  Heavy Metal
  (1608, 1260), -- Metal  ->  Industrial Metal
  (1608, 1383), -- Metal  ->  Kawaii Metal
  (1608, 1609), -- Metal  ->  Metalcore
  (1608, 1743), -- Metal  ->  Neoclassical Metal
  (1608, 2018), -- Metal  ->  Post-Metal
  (1608, 2024), -- Metal  ->  Power Metal
  (1608, 2046), -- Metal  ->  Progressive Metal
  (1608, 2345), -- Metal  ->  Sludge Metal
  (1608, 2394), -- Metal  ->  Southern Metal
  (1608, 2428), -- Metal  ->  Stenchcore
  (1608, 2432), -- Metal  ->  Stoner Metal
  (1608, 2463), -- Metal  ->  Symphonic Metal
  (1608, 2547), -- Metal  ->  Thrash Metal
  (1608, 2594), -- Metal  ->  Trance Metal
  (1608, 2708), -- Metal  ->  Viking Metal
  (1609, 698), -- Metalcore  ->  Deathcore
  (1609, 1572), -- Metalcore  ->  Mathcore
  (1609, 1596), -- Metalcore  ->  Melodic Metalcore
  (1609, 2539), -- Metalcore  ->  Thall
  (1610, 423), -- Mexican Folk Music  ->  Canto cardenche
  (1610, 1965), -- Mexican Folk Music  ->  Pirekua
  (1610, 2356), -- Mexican Folk Music  ->  Son calentano
  (1610, 2359), -- Mexican Folk Music  ->  Son huasteco
  (1610, 2360), -- Mexican Folk Music  ->  Son istmeño
  (1610, 2361), -- Mexican Folk Music  ->  Son jarocho
  (1610, 2619), -- Mexican Folk Music  ->  Trova yucateca
  (1611, 212), -- Mexican Music  ->  Bandas de viento de México
  (1611, 507), -- Mexican Music  ->  Chilena
  (1611, 593), -- Mexican Music  ->  Corrido
  (1611, 638), -- Mexican Music  ->  Cumbia mexicana
  (1611, 649), -- Mexican Music  ->  Cumbiatón
  (1611, 1561), -- Mexican Music  ->  Mariachi
  (1611, 1610), -- Mexican Music  ->  Mexican Folk Music
  (1611, 1820), -- Mexican Music  ->  Norteño
  (1611, 2105), -- Mexican Music  ->  Ranchera
  (1611, 2526), -- Mexican Music  ->  Tejano Music
  (1613, 151), -- Miami Bass  ->  Atlanta Bass
  (1613, 2488), -- Miami Bass  ->  Tamborzão
  (1613, 2515), -- Miami Bass  ->  Techno Bass
  (1617, 1373), -- Micronesian Music  ->  Kantan Chamorrita
  (1620, 289), -- MIDI Music  ->  Black MIDI
  (1629, 1994), -- Minangkabau Music  ->  Pop Minang
  (1629, 2210), -- Minangkabau Music  ->  Saluang klasik
  (1629, 2482), -- Minangkabau Music  ->  Talempong
  (1632, 160), -- Minimal Drum and Bass  ->  Autonomic
  (1632, 1614), -- Minimal Drum and Bass  ->  Microfunk
  (1634, 785), -- Minimal Techno  ->  Dub Techno
  (1635, 1633), -- Minimal Wave  ->  Minimal Synth
  (1636, 1197), -- Minimalism  ->  Holy Minimalism
  (1643, 1644), -- Mod  ->  Mod Revival
  (1646, 1312), -- Modal Jazz  ->  Jazz Mugham
  (1647, 92), -- Modern Classical  ->  American Gamelan
  (1647, 877), -- Modern Classical  ->  Expressionism
  (1647, 1009), -- Modern Classical  ->  Futurism
  (1647, 1234), -- Modern Classical  ->  Impressionism
  (1647, 1236), -- Modern Classical  ->  Indeterminacy
  (1647, 1618), -- Modern Classical  ->  Microtonal Classical
  (1647, 1636), -- Modern Classical  ->  Minimalism
  (1647, 1692), -- Modern Classical  ->  Musique concrète instrumentale
  (1647, 1751), -- Modern Classical  ->  Neoromanticism
  (1647, 1766), -- Modern Classical  ->  New Complexity
  (1647, 2019), -- Modern Classical  ->  Post-Minimalism
  (1647, 2037), -- Modern Classical  ->  Process Music
  (1647, 2274), -- Modern Classical  ->  Serialism
  (1647, 2367), -- Modern Classical  ->  Sonorism
  (1647, 2409), -- Modern Classical  ->  Spectralism
  (1647, 2430), -- Modern Classical  ->  Stochastic Music
  (1650, 2273), -- Modinha  ->  Seresta
  (1651, 1652), -- Molam  ->  Molam sing
  (1653, 304), -- Mongolian Music  ->  Bogino duu
  (1653, 393), -- Mongolian Music  ->  Buryat Folk Music
  (1653, 1367), -- Mongolian Music  ->  Kalmyk Music
  (1653, 1654), -- Mongolian Music  ->  Mongolian Throat Singing
  (1653, 2676), -- Mongolian Music  ->  Urtiin duu
  (1653, 2813), -- Mongolian Music  ->  Zohioliin duu
  (1678, 2614), -- MPB  ->  Tropicália
  (1683, 1684), -- Murga  ->  Murga uruguaya
  (1685, 2460), -- Musette  ->  Swing musette
  (1687, 564), -- Musical Comedy  ->  Comedy Rap
  (1687, 565), -- Musical Comedy  ->  Comedy Rock
  (1687, 2256), -- Musical Comedy  ->  Scrumpy and Western
  (1689, 197), -- Musical Theatre and Entertainment  ->  Ballad Opera
  (1689, 400), -- Musical Theatre and Entertainment  ->  Cabaret
  (1689, 570), -- Musical Theatre and Entertainment  ->  Comédie-ballet
  (1689, 650), -- Musical Theatre and Entertainment  ->  Cuplé
  (1689, 795), -- Musical Theatre and Entertainment  ->  Dutch Cabaret
  (1689, 1355), -- Musical Theatre and Entertainment  ->  Kabarett
  (1689, 1374), -- Musical Theatre and Entertainment  ->  Kanto
  (1689, 1638), -- Musical Theatre and Entertainment  ->  Minstrelsy
  (1689, 1683), -- Musical Theatre and Entertainment  ->  Murga
  (1689, 1686), -- Musical Theatre and Entertainment  ->  Music Hall
  (1689, 1884), -- Musical Theatre and Entertainment  ->  Operetta
  (1689, 1962), -- Musical Theatre and Entertainment  ->  Piosenka aktorska
  (1689, 2137), -- Musical Theatre and Entertainment  ->  Revue
  (1689, 2160), -- Musical Theatre and Entertainment  ->  Rock Musical
  (1689, 2306), -- Musical Theatre and Entertainment  ->  Show Tunes
  (1689, 2311), -- Musical Theatre and Entertainment  ->  Siffleur
  (1689, 2318), -- Musical Theatre and Entertainment  ->  Singspiel
  (1689, 2697), -- Musical Theatre and Entertainment  ->  Vaudeville
  (1696, 1698), -- Muzika mizrahit  ->  Muzikat dika'on
  (1703, 1702), -- Métis Music  ->  Métis Fiddling
  (1705, 890), -- Música criolla peruana  ->  Festejo
  (1705, 1451), -- Música criolla peruana  ->  Landó
  (1705, 1562), -- Música criolla peruana  ->  Marinera
  (1705, 1983), -- Música criolla peruana  ->  Polka peruana
  (1705, 2565), -- Música criolla peruana  ->  Tondero
  (1705, 2688), -- Música criolla peruana  ->  Vals criollo
  (1708, 2691), -- Música gaúcha  ->  Vanera
  (1710, 1748), -- Música típica chilena  ->  Neofolklore
  (1721, 608), -- Nashville Sound  ->  Countrypolitan
  (1723, 108), -- Nature Recordings  ->  Animal Sounds
  (1723, 2103), -- Nature Recordings  ->  Rain Sounds
  (1726, 184), -- Naxi Music  ->  Baisha xiyue
  (1726, 754), -- Naxi Music  ->  Dongjing
  (1728, 1916), -- Nederpop  ->  Palingsound
  (1736, 220), -- Neo-Medieval Folk  ->  Bardcore
  (1739, 180), -- Neo-Psychedelia  ->  Baggy
  (1739, 765), -- Neo-Psychedelia  ->  Dream Pop
  (1739, 1222), -- Neo-Psychedelia  ->  Hypnagogic Pop
  (1739, 1914), -- Neo-Psychedelia  ->  Paisley Underground
  (1739, 2403), -- Neo-Psychedelia  ->  Space Rock Revival
  (1747, 681), -- Neofolk  ->  Dark Folk
  (1762, 106), -- New Age  ->  Andean New Age
  (1762, 461), -- New Age  ->  Celtic New Age
  (1762, 1722), -- New Age  ->  Native American New Age
  (1762, 1744), -- New Age  ->  Neoclassical New Age
  (1762, 1763), -- New Age  ->  New Age Kirtan
  (1762, 2552), -- New Age  ->  Tibetan New Age
  (1764, 1134), -- New Beat  ->  Hard Beat
  (1783, 3), -- New Wave  ->  2 Tone
  (1783, 247), -- New Wave  ->  Beat Rock
  (1783, 1644), -- New Wave  ->  Mod Revival
  (1788, 2230), -- New York Drill  ->  Sample Drill
  (1788, 2283), -- New York Drill  ->  Sexy Drill
  (1793, 2669), -- Ngoma  ->  Unyago
  (1809, 85), -- Noise  ->  Ambient Noise Wall
  (1809, 290), -- Noise  ->  Black Noise
  (1809, 1075), -- Noise  ->  Gorenoise
  (1809, 1158), -- Noise  ->  Harsh Noise
  (1809, 2023), -- Noise  ->  Power Electronics
  (1809, 2025), -- Noise  ->  Power Noise
  (1811, 1957), -- Noise Rock  ->  Pigfuck
  (1811, 2301), -- Noise Rock  ->  Shitgaze
  (1815, 671), -- Nordic Folk Music  ->  Danish Folk Music
  (1815, 889), -- Nordic Folk Music  ->  Faroese Folk Music
  (1815, 906), -- Nordic Folk Music  ->  Finnish Folk Music
  (1815, 1227), -- Nordic Folk Music  ->  Icelandic Folk Music
  (1815, 1337), -- Nordic Folk Music  ->  Joik
  (1815, 1818), -- Nordic Folk Music  ->  Nordic Old Time Dance Music
  (1815, 1830), -- Nordic Folk Music  ->  Norwegian Folk Music
  (1815, 2457), -- Nordic Folk Music  ->  Swedish Folk Music
  (1817, 673), -- Nordic Music  ->  Dansbandsmusik
  (1817, 674), -- Nordic Music  ->  Dansktop
  (1817, 907), -- Nordic Music  ->  Finnish Tango
  (1817, 1088), -- Nordic Music  ->  Greenlandic Music
  (1817, 1815), -- Nordic Music  ->  Nordic Folk Music
  (1817, 1816), -- Nordic Music  ->  Nordic Folk Rock
  (1817, 2117), -- Nordic Music  ->  Rautalanka
  (1817, 2714), -- Nordic Music  ->  Visa
  (1818, 1985), -- Nordic Old Time Dance Music  ->  Polska
  (1820, 639), -- Norteño  ->  Cumbia norteña mexicana
  (1820, 794), -- Norteño  ->  Duranguense
  (1820, 1676), -- Norteño  ->  Movimiento Alterado
  (1820, 2310), -- Norteño  ->  Sierreño
  (1821, 79), -- North African Music  ->  Amazigh Music
  (1821, 816), -- North African Music  ->  Egyptian Music
  (1821, 1516), -- North African Music  ->  Maghrebi Music
  (1821, 1662), -- North African Music  ->  Moorish Music
  (1822, 52), -- North Asian Music  ->  Ainu Music
  (1822, 534), -- North Asian Music  ->  Chukchi Folk Music
  (1822, 1362), -- North Asian Music  ->  Kai
  (1822, 1392), -- North Asian Music  ->  Khakas Traditional Music
  (1822, 1540), -- North Asian Music  ->  Manchu Music
  (1822, 1653), -- North Asian Music  ->  Mongolian Music
  (1822, 1803), -- North Asian Music  ->  Nivkh Music
  (1822, 1864), -- North Asian Music  ->  Ob-Ugric Folk Music
  (1822, 2204), -- North Asian Music  ->  Sakha Traditional Music
  (1822, 2229), -- North Asian Music  ->  Samoyedic Folk Music
  (1822, 2642), -- North Asian Music  ->  Tuvan Throat Singing
  (1823, 31), -- Northeastern African Music  ->  Afar Music
  (1823, 254), -- Northeastern African Music  ->  Beja Music
  (1823, 735), -- Northeastern African Music  ->  Dinka Music
  (1823, 858), -- Northeastern African Music  ->  Ethiopic Music
  (1823, 1847), -- Northeastern African Music  ->  Nubian Music
  (1823, 1848), -- Northeastern African Music  ->  Nuer Music
  (1823, 1896), -- Northeastern African Music  ->  Oromo Music
  (1823, 2299), -- Northeastern African Music  ->  Shilluk Music
  (1823, 2355), -- Northeastern African Music  ->  Somali Music
  (1823, 2740), -- Northeastern African Music  ->  Welayta Music
  (1824, 10), -- Northeastern Brazilian Music  ->  Aboio
  (1824, 32), -- Northeastern Brazilian Music  ->  Afoxé
  (1824, 128), -- Northeastern Brazilian Music  ->  Arrocha
  (1824, 169), -- Northeastern Brazilian Music  ->  Axé
  (1824, 186), -- Northeastern Brazilian Music  ->  Baião
  (1824, 208), -- Northeastern Brazilian Music  ->  Banda de pífano
  (1824, 343), -- Northeastern Brazilian Music  ->  Brega funk
  (1824, 428), -- Northeastern Brazilian Music  ->  Cantoria
  (1824, 557), -- Northeastern Brazilian Music  ->  Coco
  (1824, 936), -- Northeastern Brazilian Music  ->  Forró
  (1824, 966), -- Northeastern Brazilian Music  ->  Frevo
  (1824, 1545), -- Northeastern Brazilian Music  ->  Manguebeat
  (1824, 1555), -- Northeastern Brazilian Music  ->  Maracatu
  (1824, 2214), -- Northeastern Brazilian Music  ->  Samba de roda
  (1824, 2521), -- Northeastern Brazilian Music  ->  Tecnobrega
  (1824, 2651), -- Northeastern Brazilian Music  ->  Udigrudi
  (1824, 2667), -- Northeastern Brazilian Music  ->  Unakesa
  (1824, 2767), -- Northeastern Brazilian Music  ->  Xaxado
  (1825, 82), -- Northern American Music  ->  Ambient Americana
  (1825, 91), -- Northern American Music  ->  American Folk Music
  (1825, 93), -- Northern American Music  ->  American Primitivism
  (1825, 218), -- Northern American Music  ->  Barbershop
  (1825, 287), -- Northern American Music  ->  Black Gospel
  (1825, 317), -- Northern American Music  ->  Boogie Woogie
  (1825, 411), -- Northern American Music  ->  Canadian Folk Music
  (1825, 486), -- Northern American Music  ->  Chanson québécoise
  (1825, 499), -- Northern American Music  ->  Chicago Polka
  (1825, 588), -- Northern American Music  ->  Coon Song
  (1825, 597), -- Northern American Music  ->  Country
  (1825, 605), -- Northern American Music  ->  Country Rock
  (1825, 610), -- Northern American Music  ->  Cowboy Poetry
  (1825, 808), -- Northern American Music  ->  Eastern-Style Polka
  (1825, 941), -- Northern American Music  ->  Foxtrot
  (1825, 1088), -- Northern American Music  ->  Greenlandic Music
  (1825, 1129), -- Northern American Music  ->  Hapa haole
  (1825, 1249), -- Northern American Music  ->  Indigenous North American Music
  (1825, 1496), -- Northern American Music  ->  Louisiana Music
  (1825, 1638), -- Northern American Music  ->  Minstrelsy
  (1825, 1772), -- Northern American Music  ->  New Mexico Music
  (1825, 1937), -- Northern American Music  ->  Pep Band
  (1825, 2101), -- Northern American Music  ->  Ragtime
  (1825, 2185), -- Northern American Music  ->  Roots Rock
  (1825, 2287), -- Northern American Music  ->  Shaker Music
  (1825, 2392), -- Northern American Music  ->  Southern Gospel
  (1825, 2534), -- Northern American Music  ->  Texan Music
  (1825, 2556), -- Northern American Music  ->  Tin Pan Alley
  (1825, 2697), -- Northern American Music  ->  Vaudeville
  (1826, 342), -- Northern Brazilian Music  ->  Brega calypso
  (1826, 445), -- Northern Brazilian Music  ->  Carimbó
  (1849, 1851), -- Nueva canción  ->  Nueva canción española
  (1849, 1852), -- Nueva canción  ->  Nueva canción latinoamericana
  (1852, 1850), -- Nueva canción latinoamericana  ->  Nueva canción chilena
  (1852, 1856), -- Nueva canción latinoamericana  ->  Nueva trova
  (1852, 1857), -- Nueva canción latinoamericana  ->  Nuevo Cancionero
  (1863, 2729), -- O'odham Music  ->  Waila
  (1866, 161), -- Occitan Folk Music  ->  Auvergnat Folk Music
  (1866, 1043), -- Occitan Folk Music  ->  Gascon Folk Music
  (1866, 1976), -- Occitan Folk Music  ->  Polifonia occitana
  (1868, 157), -- Oceanian Music  ->  Australian Folk Music
  (1868, 1248), -- Oceanian Music  ->  Indigenous Australian Traditional Music
  (1868, 1588), -- Oceanian Music  ->  Melanesian Music
  (1868, 1617), -- Oceanian Music  ->  Micronesian Music
  (1868, 1908), -- Oceanian Music  ->  Pacific Reggae
  (1868, 1986), -- Oceanian Music  ->  Polynesian Music
  (1880, 197), -- Opera  ->  Ballad Opera
  (1880, 1083), -- Opera  ->  Grand opéra
  (1880, 1656), -- Opera  ->  Monodrama
  (1880, 1881), -- Opera  ->  Opera buffa
  (1880, 1882), -- Opera  ->  Opera semiseria
  (1880, 1883), -- Opera  ->  Opera seria
  (1880, 1884), -- Opera  ->  Operetta
  (1880, 1886), -- Opera  ->  Opéra-ballet
  (1880, 1887), -- Opera  ->  Opéra-comique
  (1880, 2181), -- Opera  ->  Romantische Oper
  (1880, 2318), -- Opera  ->  Singspiel
  (1880, 2589), -- Opera  ->  Tragédie en musique
  (1880, 2701), -- Opera  ->  Verismo
  (1880, 2797), -- Opera  ->  Zarzuela
  (1880, 2800), -- Opera  ->  Zeitoper
  (1884, 1368), -- Operetta  ->  Kalon'ny fahiny
  (1889, 1890), -- Orchestral Music  ->  Orchestral Song
  (1889, 2464), -- Orchestral Music  ->  Symphonic Mugham
  (1889, 2566), -- Orchestral Music  ->  Tone Poem
  (1894, 216), -- Oriental Jewish Music  ->  Baqashot
  (1894, 2782), -- Oriental Jewish Music  ->  Yemenite Jewish Diwan
  (1903, 1490), -- Outsider House  ->  Lo-Fi House
  (1908, 1307), -- Pacific Reggae  ->  Jawaiian
  (1911, 1912), -- Pagode  ->  Pagode romântico
  (1911, 1913), -- Pagode  ->  Pagodão
  (1913, 131), -- Pagodão  ->  Arrochadeira
  (1920, 882), -- Pamiri Music  ->  Falak
  (1935, 1417), -- Peking Opera  ->  Korean Revolutionary Opera
  (1935, 2136), -- Peking Opera  ->  Revolutionary Opera
  (1940, 15), -- Persian Music  ->  Achomi Music
  (1940, 211), -- Persian Music  ->  Bandari
  (1940, 1410), -- Persian Music  ->  Koche bazari
  (1940, 1938), -- Persian Music  ->  Persian Classical Music
  (1940, 1939), -- Persian Music  ->  Persian Folk Music
  (1940, 1941), -- Persian Music  ->  Persian Pop
  (1942, 513), -- Peruvian Music  ->  Chimaychi
  (1942, 590), -- Peruvian Music  ->  Coplas cajamarquinas
  (1942, 641), -- Peruvian Music  ->  Cumbia peruana
  (1942, 1209), -- Peruvian Music  ->  Huaylarsh
  (1942, 1705), -- Peruvian Music  ->  Música criolla peruana
  (1942, 1921), -- Peruvian Music  ->  Pandilla
  (1942, 2629), -- Peruvian Music  ->  Tunantada
  (1944, 192), -- Philippine Music  ->  Balitaw
  (1944, 1132), -- Philippine Music  ->  Harana
  (1944, 1231), -- Philippine Music  ->  Igorot Music
  (1944, 1233), -- Philippine Music  ->  Ilocano Music
  (1944, 1434), -- Philippine Music  ->  Kundiman
  (1944, 1885), -- Philippine Music  ->  OPM
  (1944, 1945), -- Philippine Music  ->  Philippine Rondalla
  (1944, 1960), -- Philippine Music  ->  Pinoy Folk Rock
  (1967, 216), -- Piyyut  ->  Baqashot
  (1967, 2801), -- Piyyut  ->  Zemirot
  (1969, 90), -- Plainsong  ->  Ambrosian Chant
  (1969, 422), -- Plainsong  ->  Canto beneventano
  (1969, 425), -- Plainsong  ->  Canto mozárabe
  (1969, 457), -- Plainsong  ->  Celtic Chant
  (1969, 1020), -- Plainsong  ->  Gallican Chant
  (1969, 1090), -- Plainsong  ->  Gregorian Chant
  (1969, 1874), -- Plainsong  ->  Old Roman Chant
  (1971, 86), -- Plugg  ->  Ambient Plugg
  (1971, 684), -- Plugg  ->  Dark Plugg
  (1971, 1972), -- Plugg  ->  PluggnB
  (1971, 2530), -- Plugg  ->  Terror Plugg
  (1972, 143), -- PluggnB  ->  Asian Rock
  (1974, 246), -- Poetry  ->  Beat Poetry
  (1974, 610), -- Poetry  ->  Cowboy Poetry
  (1974, 784), -- Poetry  ->  Dub Poetry
  (1974, 1313), -- Poetry  ->  Jazz Poetry
  (1974, 2072), -- Poetry  ->  Punk Poetry
  (1974, 2336), -- Poetry  ->  Slam Poetry
  (1974, 2377), -- Poetry  ->  Sound Poetry
  (1977, 927), -- Polish Folk Music  ->  Folklor miejski
  (1977, 1381), -- Polish Folk Music  ->  Kashubian Folk Music
  (1977, 1420), -- Polish Folk Music  ->  Krakowiak
  (1977, 1429), -- Polish Folk Music  ->  Kujawiak
  (1977, 1430), -- Polish Folk Music  ->  Kujon
  (1977, 1437), -- Polish Folk Music  ->  Kurpian Folk Music
  (1977, 1865), -- Polish Folk Music  ->  Oberek
  (1977, 1978), -- Polish Folk Music  ->  Polish Goral Music
  (1979, 499), -- Polish Music  ->  Chicago Polka
  (1979, 738), -- Polish Music  ->  Disco polo
  (1979, 808), -- Polish Music  ->  Eastern-Style Polka
  (1979, 1575), -- Polish Music  ->  Mazur
  (1979, 1576), -- Polish Music  ->  Mazurka
  (1979, 1624), -- Polish Music  ->  Miejski folk
  (1979, 1962), -- Polish Music  ->  Piosenka aktorska
  (1979, 1975), -- Polish Music  ->  Poezja śpiewana
  (1979, 1977), -- Polish Music  ->  Polish Folk Music
  (1979, 1984), -- Polish Music  ->  Polonaise
  (1981, 499), -- Polka  ->  Chicago Polka
  (1981, 808), -- Polka  ->  Eastern-Style Polka
  (1981, 1983), -- Polka  ->  Polka peruana
  (1985, 1123), -- Polska  ->  Hambo
  (1986, 899), -- Polynesian Music  ->  Fijian Music
  (1986, 1163), -- Polynesian Music  ->  Hawaiian Music
  (1986, 1180), -- Polynesian Music  ->  Himene tarava
  (1986, 1711), -- Polynesian Music  ->  Māori Music
  (1986, 2228), -- Polynesian Music  ->  Samoan Music
  (1986, 2478), -- Polynesian Music  ->  Tahitian Music
  (1987, 133), -- Polyphonic Chant  ->  Ars nova
  (1987, 134), -- Polyphonic Chant  ->  Ars subtilior
  (1987, 419), -- Polyphonic Chant  ->  Cante alentejano
  (1987, 430), -- Polyphonic Chant  ->  Cantu a tenore
  (1987, 586), -- Polyphonic Chant  ->  Contenance angloise
  (1987, 1034), -- Polyphonic Chant  ->  Ganga
  (1987, 1180), -- Polyphonic Chant  ->  Himene tarava
  (1987, 1286), -- Polyphonic Chant  ->  Izvorna bosanska muzika
  (1987, 1446), -- Polyphonic Chant  ->  Lab Polyphony
  (1987, 1513), -- Polyphonic Chant  ->  Madrigal
  (1987, 1910), -- Polyphonic Chant  ->  Paghjella
  (1987, 1976), -- Polyphonic Chant  ->  Polifonia occitana
  (1987, 2280), -- Polyphonic Chant  ->  Seto leelo
  (1987, 2452), -- Polyphonic Chant  ->  Sutartinės
  (1987, 2569), -- Polyphonic Chant  ->  Tosk Polyphony
  (1987, 2590), -- Polyphonic Chant  ->  Trallalero
  (1990, 29), -- Pop  ->  Adult Contemporary
  (1990, 43), -- Pop  ->  Afrobeats
  (1990, 69), -- Pop  ->  Alt-Pop
  (1990, 121), -- Pop  ->  Arabic Pop
  (1990, 135), -- Pop  ->  Art Pop
  (1990, 196), -- Pop  ->  Balkan Pop-Folk
  (1990, 222), -- Pop  ->  Baroque Pop
  (1990, 283), -- Pop  ->  Bitpop
  (1990, 297), -- Pop  ->  Blue-Eyed Soul
  (1990, 328), -- Pop  ->  Boy Band
  (1990, 342), -- Pop  ->  Brega calypso
  (1990, 348), -- Pop  ->  Brill Building
  (1990, 374), -- Pop  ->  Bubblegum
  (1990, 397), -- Pop  ->  C-Pop
  (1990, 408), -- Pop  ->  Cambodian Pop
  (1990, 414), -- Pop  ->  Canción melódica
  (1990, 546), -- Pop  ->  City Pop
  (1990, 548), -- Pop  ->  Classical Crossover
  (1990, 603), -- Pop  ->  Country Pop
  (1990, 663), -- Pop  ->  Dance-Pop
  (1990, 669), -- Pop  ->  Dangdut
  (1990, 673), -- Pop  ->  Dansbandsmusik
  (1990, 674), -- Pop  ->  Dansktop
  (1990, 820), -- Pop  ->  Electro Hop
  (1990, 832), -- Pop  ->  Electropop
  (1990, 869), -- Pop  ->  Europop
  (1990, 912), -- Pop  ->  Flamenco Pop
  (1990, 923), -- Pop  ->  Folk Pop
  (1990, 963), -- Pop  ->  French Pop
  (1990, 1057), -- Pop  ->  Girl Group
  (1990, 1192), -- Pop  ->  Hmong Pop
  (1990, 1219), -- Pop  ->  Hyperpop
  (1990, 1237), -- Pop  ->  Indian Pop
  (1990, 1239), -- Pop  ->  Indie Pop
  (1990, 1274), -- Pop  ->  Irish Showband
  (1990, 1283), -- Pop  ->  Italo Pop
  (1990, 1289), -- Pop  ->  J-Pop
  (1990, 1314), -- Pop  ->  Jazz Pop
  (1990, 1354), -- Pop  ->  K-Pop
  (1990, 1384), -- Pop  ->  Kayōkyoku
  (1990, 1413), -- Pop  ->  Korean Ballad
  (1990, 1462), -- Pop  ->  Latin Pop
  (1990, 1492), -- Pop  ->  Lokal musik
  (1990, 1681), -- Pop  ->  Mulatós
  (1990, 1728), -- Pop  ->  Nederpop
  (1990, 1773), -- Pop  ->  New Music
  (1990, 1885), -- Pop  ->  OPM
  (1990, 1897), -- Pop  ->  Orthodox Pop
  (1990, 1906), -- Pop  ->  P-Pop
  (1990, 1941), -- Pop  ->  Persian Pop
  (1990, 1991), -- Pop  ->  Pop Batak
  (1990, 1992), -- Pop  ->  Pop Ghazal
  (1990, 1994), -- Pop  ->  Pop Minang
  (1990, 1997), -- Pop  ->  Pop Raï
  (1990, 1998), -- Pop  ->  Pop Reggae
  (1990, 1999), -- Pop  ->  Pop Rock
  (1990, 2000), -- Pop  ->  Pop Soul
  (1990, 2001), -- Pop  ->  Pop Sunda
  (1990, 2047), -- Pop  ->  Progressive Pop
  (1990, 2058), -- Pop  ->  Psychedelic Pop
  (1990, 2090), -- Pop  ->  Rabiz
  (1990, 2142), -- Pop  ->  Rigsar
  (1990, 2186), -- Pop  ->  Rumba catalana
  (1990, 2191), -- Pop  ->  Russian Chanson
  (1990, 2247), -- Pop  ->  Schlager
  (1990, 2278), -- Pop  ->  Sertanejo romântico
  (1990, 2279), -- Pop  ->  Sertanejo universitário
  (1990, 2368), -- Pop  ->  Sophisti-Pop
  (1990, 2397), -- Pop  ->  Soviet Estrada
  (1990, 2447), -- Pop  ->  Sunshine Pop
  (1990, 2470), -- Pop  ->  Synthpop
  (1990, 2502), -- Pop  ->  Tarz
  (1990, 2525), -- Pop  ->  Teen Pop
  (1990, 2575), -- Pop  ->  Toytown Pop
  (1990, 2586), -- Pop  ->  Traditional Pop
  (1990, 2637), -- Pop  ->  Turkish Pop
  (1990, 2720), -- Pop  ->  Vocal Trance
  (1990, 2792), -- Pop  ->  Yé-yé
  (1994, 2483), -- Pop Minang  ->  Talempong goyang
  (1995, 810), -- Pop Punk  ->  Easycore
  (1995, 1749), -- Pop Punk  ->  Neon Pop Punk
  (1995, 2266), -- Pop Punk  ->  Seishun Punk
  (1996, 319), -- Pop Rap  ->  Bop
  (1996, 945), -- Pop Rap  ->  Frat Rap
  (1996, 1010), -- Pop Rap  ->  Futuristic Swag
  (1999, 242), -- Pop Rock  ->  Beat
  (1999, 247), -- Pop Rock  ->  Beat Rock
  (1999, 273), -- Pop Rock  ->  Big Music
  (1999, 360), -- Pop Rock  ->  Britpop
  (1999, 1298), -- Pop Rock  ->  Jangle Pop
  (1999, 1749), -- Pop Rock  ->  Neon Pop Punk
  (1999, 1954), -- Pop Rock  ->  Piano Rock
  (1999, 2002), -- Pop Rock  ->  Pop Yeh-Yeh
  (1999, 2013), -- Pop Rock  ->  Post-Britpop
  (1999, 2026), -- Pop Rock  ->  Power Pop
  (1999, 2351), -- Pop Rock  ->  Soft Rock
  (1999, 2429), -- Pop Rock  ->  Stereo
  (1999, 2644), -- Pop Rock  ->  Twee Pop
  (1999, 2719), -- Pop Rock  ->  Vocal Surf
  (2000, 1672), -- Pop Soul  ->  Motown Sound
  (2007, 419), -- Portuguese Folk Music  ->  Cante alentejano
  (2007, 473), -- Portuguese Folk Music  ->  Chamarrita açoriana
  (2007, 719), -- Portuguese Folk Music  ->  Desgarrada
  (2007, 879), -- Portuguese Folk Music  ->  Fado
  (2007, 2621), -- Portuguese Folk Music  ->  Trás-os-Montes Folk Music
  (2007, 2712), -- Portuguese Folk Music  ->  Vira
  (2008, 1706), -- Portuguese Music  ->  Música de intervenção
  (2008, 1959), -- Portuguese Music  ->  Pimba
  (2008, 2007), -- Portuguese Music  ->  Portuguese Folk Music
  (2016, 842), -- Post-Hardcore  ->  Emocore
  (2016, 1532), -- Post-Hardcore  ->  Mall Screamo
  (2016, 2255), -- Post-Hardcore  ->  Screamo
  (2016, 2456), -- Post-Hardcore  ->  Swancore
  (2017, 677), -- Post-Industrial  ->  Dark Ambient
  (2017, 703), -- Post-Industrial  ->  Deconstructed Club
  (2017, 811), -- Post-Industrial  ->  EBM
  (2017, 826), -- Post-Industrial  ->  Electro-Industrial
  (2017, 1258), -- Post-Industrial  ->  Industrial Hardcore
  (2017, 1259), -- Post-Industrial  ->  Industrial Hip Hop
  (2017, 1260), -- Post-Industrial  ->  Industrial Metal
  (2017, 1261), -- Post-Industrial  ->  Industrial Rock
  (2017, 1262), -- Post-Industrial  ->  Industrial Techno
  (2017, 1564), -- Post-Industrial  ->  Martial Industrial
  (2017, 2025), -- Post-Industrial  ->  Power Noise
  (2018, 154), -- Post-Metal  ->  Atmospheric Sludge Metal
  (2018, 294), -- Post-Metal  ->  Blackgaze
  (2018, 760), -- Post-Metal  ->  Doomgaze
  (2019, 2570), -- Post-Minimalism  ->  Totalism
  (2020, 560), -- Post-Punk  ->  Coldwave
  (2020, 664), -- Post-Punk  ->  Dance-Punk
  (2020, 1081), -- Post-Punk  ->  Gothic Rock
  (2020, 2021), -- Post-Punk  ->  Post-Punk Revival
  (2021, 665), -- Post-Punk Revival  ->  Dance-Punk Revival
  (2023, 695), -- Power Electronics  ->  Death Industrial
  (2031, 2032), -- Praise & Worship  ->  Praise Break
  (2040, 1297), -- Progressive Bluegrass  ->  Jamgrass
  (2042, 1901), -- Progressive Country  ->  Outlaw Country
  (2043, 266), -- Progressive Electronic  ->  Berlin School
  (2045, 2829), -- Progressive House  ->  Epic House
  (2048, 2802), -- Progressive Psytrance  ->  Zenonesque
  (2049, 165), -- Progressive Rock  ->  Avant-Prog
  (2049, 420), -- Progressive Rock  ->  Canterbury Scene
  (2049, 1738), -- Progressive Rock  ->  Neo-Prog
  (2049, 2465), -- Progressive Rock  ->  Symphonic Prog
  (2056, 1739), -- Psychedelia  ->  Neo-Psychedelia
  (2056, 2057), -- Psychedelia  ->  Psychedelic Folk
  (2056, 2058), -- Psychedelia  ->  Psychedelic Pop
  (2056, 2059), -- Psychedelia  ->  Psychedelic Rock
  (2056, 2060), -- Psychedelia  ->  Psychedelic Soul
  (2056, 2062), -- Psychedelia  ->  Psychsploitation
  (2056, 2432), -- Psychedelia  ->  Stoner Metal
  (2056, 2434), -- Psychedelia  ->  Stoner Rock
  (2056, 2614), -- Psychedelia  ->  Tropicália
  (2057, 947), -- Psychedelic Folk  ->  Freak Folk
  (2057, 950), -- Psychedelic Folk  ->  Free Folk
  (2057, 2651), -- Psychedelic Folk  ->  Udigrudi
  (2057, 2766), -- Psychedelic Folk  ->  Wyrd Folk
  (2059, 19), -- Psychedelic Rock  ->  Acid Rock
  (2059, 948), -- Psychedelic Rock  ->  Freakbeat
  (2059, 1037), -- Psychedelic Rock  ->  Garage Psych
  (2059, 1168), -- Psychedelic Rock  ->  Heavy Psych
  (2059, 2095), -- Psychedelic Rock  ->  Raga Rock
  (2059, 2402), -- Psychedelic Rock  ->  Space Rock
  (2059, 2768), -- Psychedelic Rock  ->  Xian Psych
  (2059, 2796), -- Psychedelic Rock  ->  Zamrock
  (2059, 2856), -- Psychedelic Rock  ->  La Onda
  (2061, 2839), -- Psychobilly  ->  Rustic Stomp
  (2062, 2321), -- Psychsploitation  ->  Sitarsploitation
  (2065, 685), -- Psytrance  ->  Dark Psytrance
  (2065, 935), -- Psytrance  ->  Forest Psytrance
  (2065, 975), -- Psytrance  ->  Full-On Psytrance
  (2065, 1067), -- Psytrance  ->  Goa Trance
  (2065, 2048), -- Psytrance  ->  Progressive Psytrance
  (2065, 2448), -- Psytrance  ->  Suomisaundi
  (2070, 136), -- Punk  ->  Art Punk
  (2070, 611), -- Punk  ->  Cowpunk
  (2070, 732), -- Punk  ->  Digital Hardcore
  (2070, 838), -- Punk  ->  Emo
  (2070, 924), -- Punk  ->  Folk Punk
  (2070, 1145), -- Punk  ->  Hardcore [Punk]
  (2070, 1644), -- Punk  ->  Mod Revival
  (2070, 1957), -- Punk  ->  Pigfuck
  (2070, 2020), -- Punk  ->  Post-Punk
  (2070, 2052), -- Punk  ->  Proto-Punk
  (2070, 2071), -- Punk  ->  Punk Blues
  (2070, 2072), -- Punk  ->  Punk Poetry
  (2070, 2073), -- Punk  ->  Punk Rock
  (2070, 2469), -- Punk  ->  Synth Punk
  (2073, 96), -- Punk Rock  ->  Anarcho-Punk
  (2073, 462), -- Punk Rock  ->  Celtic Punk
  (2073, 700), -- Punk Rock  ->  Deathrock
  (2073, 723), -- Punk Rock  ->  Deutschpunk
  (2073, 815), -- Punk Rock  ->  Egg Punk
  (2073, 1038), -- Punk Rock  ->  Garage Punk
  (2073, 1059), -- Punk Rock  ->  Glam Punk
  (2073, 1148), -- Punk Rock  ->  Hardcore Punk
  (2073, 1203), -- Punk Rock  ->  Horror Punk
  (2073, 1443), -- Punk Rock  ->  Könsrock
  (2073, 1872), -- Punk Rock  ->  Oi!
  (2073, 1995), -- Punk Rock  ->  Pop Punk
  (2073, 2009), -- Punk Rock  ->  Positive Punk
  (2073, 2061), -- Punk Rock  ->  Psychobilly
  (2073, 2324), -- Punk Rock  ->  Ska Punk
  (2073, 2326), -- Punk Rock  ->  Skate Punk
  (2073, 2450), -- Punk Rock  ->  Surf Punk
  (2073, 2709), -- Punk Rock  ->  Vikingarock
  (2088, 18), -- R&B  ->  Acid Jazz
  (2088, 241), -- R&B  ->  Beach Music
  (2088, 297), -- R&B  ->  Blue-Eyed Soul
  (2088, 315), -- R&B  ->  Boogie
  (2088, 585), -- R&B  ->  Contemporary R&B
  (2088, 980), -- R&B  ->  Funk
  (2088, 1776), -- R&B  ->  New Orleans R&B
  (2088, 2139), -- R&B  ->  Rhythm & Blues
  (2088, 2371), -- R&B  ->  Soul
  (2088, 2372), -- R&B  ->  Soul Blues
  (2101, 405), -- Ragtime  ->  Cakewalk
  (2101, 547), -- Ragtime  ->  Classic Ragtime
  (2101, 1200), -- Ragtime  ->  Honky-Tonk Piano
  (2101, 1838), -- Ragtime  ->  Novelty Piano
  (2101, 2102), -- Ragtime  ->  Ragtime Song
  (2101, 2438), -- Ragtime  ->  Stride
  (2107, 2106), -- Rap Rock  ->  Rap Metal
  (2119, 2118), -- Rawstyle  ->  Rawphoric
  (2119, 2772), -- Rawstyle  ->  Xtra Raw
  (2120, 1997), -- Raï  ->  Pop Raï
  (2120, 2587), -- Raï  ->  Traditional Raï
  (2123, 1501), -- Reductionism  ->  Lowercase
  (2123, 1879), -- Reductionism  ->  Onkyo
  (2123, 2834), -- Reductionism  ->  New London Silence
  (2125, 704), -- Reggae  ->  Deejay
  (2125, 730), -- Reggae  ->  Digital Dancehall
  (2125, 783), -- Reggae  ->  Dub
  (2125, 1499), -- Reggae  ->  Lovers Rock
  (2125, 1908), -- Reggae  ->  Pacific Reggae
  (2125, 1998), -- Reggae  ->  Pop Reggae
  (2125, 2184), -- Reggae  ->  Roots Reggae
  (2125, 2264), -- Reggae  ->  Seggae
  (2125, 2330), -- Reggae  ->  Skinhead Reggae
  (2126, 667), -- Reggae / Ska / Dancehall  ->  Dancehall
  (2126, 2125), -- Reggae / Ska / Dancehall  ->  Reggae
  (2126, 2170), -- Reggae / Ska / Dancehall  ->  Rocksteady
  (2126, 2323), -- Reggae / Ska / Dancehall  ->  Ska
  (2128, 176), -- Reggaetón  ->  Bachatón
  (2128, 629), -- Reggaetón  ->  Cubaton
  (2128, 649), -- Reggaetón  ->  Cumbiatón
  (2128, 748), -- Reggaetón  ->  Doble paso
  (2128, 1750), -- Reggaetón  ->  Neoperreo
  (2128, 2150), -- Reggaetón  ->  RKT
  (2128, 2179), -- Reggaetón  ->  Romantic Flow
  (2129, 34), -- Regional Music  ->  African Music
  (2129, 102), -- Regional Music  ->  Ancient Music
  (2129, 120), -- Regional Music  ->  Arabic Music
  (2129, 142), -- Regional Music  ->  Asian Music
  (2129, 158), -- Regional Music  ->  Austronesian Music
  (2129, 444), -- Regional Music  ->  Caribbean Music
  (2129, 465), -- Regional Music  ->  Central American Music
  (2129, 531), -- Regional Music  ->  Christian Liturgical Music
  (2129, 868), -- Regional Music  ->  European Music
  (2129, 1076), -- Regional Music  ->  Gospel
  (2129, 1190), -- Regional Music  ->  Hispanic Music
  (2129, 1245), -- Regional Music  ->  Indigenous American Music
  (2129, 1276), -- Regional Music  ->  Islamic Religious Music & Recitation
  (2129, 1329), -- Regional Music  ->  Jewish Music
  (2129, 1553), -- Regional Music  ->  Maqāmic Music
  (2129, 1825), -- Regional Music  ->  Northern American Music
  (2129, 1868), -- Regional Music  ->  Oceanian Music
  (2129, 1987), -- Regional Music  ->  Polyphonic Chant
  (2129, 2035), -- Regional Music  ->  Prehistoric Music
  (2129, 2380), -- Regional Music  ->  South American Music
  (2129, 2441), -- Regional Music  ->  Sufi Music
  (2129, 2584), -- Regional Music  ->  Traditional Folk Music
  (2129, 2631), -- Regional Music  ->  Turkic-Mongolic Music
  (2131, 586), -- Renaissance Music  ->  Contenance angloise
  (2131, 836), -- Renaissance Music  ->  Elizabethan Song
  (2131, 942), -- Renaissance Music  ->  Franco-Flemish School
  (2139, 358), -- Rhythm & Blues  ->  British Rhythm & Blues
  (2139, 756), -- Rhythm & Blues  ->  Doo-Wop
  (2139, 2454), -- Rhythm & Blues  ->  Swamp Pop
  (2139, 2647), -- Rhythm & Blues  ->  Twist
  (2139, 2749), -- Rhythm & Blues  ->  West Side Sound
  (2141, 1007), -- Riddim  ->  Future Riddim
  (2141, 1481), -- Riddim  ->  Liquid Riddim
  (2144, 415), -- Rioplatense Music  ->  Candombe
  (2144, 416), -- Rioplatense Music  ->  Candombe beat
  (2144, 474), -- Rioplatense Music  ->  Chamarrita rioplatense
  (2144, 642), -- Rioplatense Music  ->  Cumbia pop
  (2144, 833), -- Rioplatense Music  ->  Electrotango
  (2144, 1626), -- Rioplatense Music  ->  Milonga
  (2144, 1684), -- Rioplatense Music  ->  Murga uruguaya
  (2144, 2491), -- Rioplatense Music  ->  Tango
  (2152, 26), -- Rock  ->  Acoustic Rock
  (2152, 41), -- Rock  ->  Afro-Rock
  (2152, 75), -- Rock  ->  Alternative Rock
  (2152, 97), -- Rock  ->  Anatolian Rock
  (2152, 110), -- Rock  ->  AOR
  (2152, 136), -- Rock  ->  Art Punk
  (2152, 137), -- Rock  ->  Art Rock
  (2152, 219), -- Rock  ->  Bard Rock
  (2152, 301), -- Rock  ->  Blues Rock
  (2152, 358), -- Rock  ->  British Rhythm & Blues
  (2152, 416), -- Rock  ->  Candombe beat
  (2152, 532), -- Rock  ->  Christian Rock
  (2152, 565), -- Rock  ->  Comedy Rock
  (2152, 605), -- Rock  ->  Country Rock
  (2152, 611), -- Rock  ->  Cowpunk
  (2152, 724), -- Rock  ->  Deutschrock
  (2152, 838), -- Rock  ->  Emo
  (2152, 876), -- Rock  ->  Experimental Rock
  (2152, 925), -- Rock  ->  Folk Rock
  (2152, 992), -- Rock  ->  Funk Rock
  (2152, 1039), -- Rock  ->  Garage Rock
  (2152, 1060), -- Rock  ->  Glam Rock
  (2152, 1138), -- Rock  ->  Hard Rock
  (2152, 1145), -- Rock  ->  Hardcore [Punk]
  (2152, 1165), -- Rock  ->  Heartland Rock
  (2152, 1261), -- Rock  ->  Industrial Rock
  (2152, 1293), -- Rock  ->  Jam Band
  (2152, 1317), -- Rock  ->  Jazz-Rock
  (2152, 1325), -- Rock  ->  Jersey Shore Sound
  (2152, 1464), -- Rock  ->  Latin Rock
  (2152, 1545), -- Rock  ->  Manguebeat
  (2152, 1571), -- Rock  ->  Math Rock
  (2152, 1608), -- Rock  ->  Metal
  (2152, 1624), -- Rock  ->  Miejski folk
  (2152, 1783), -- Rock  ->  New Wave
  (2152, 1811), -- Rock  ->  Noise Rock
  (2152, 1999), -- Rock  ->  Pop Rock
  (2152, 2020), -- Rock  ->  Post-Punk
  (2152, 2022), -- Rock  ->  Post-Rock
  (2152, 2049), -- Rock  ->  Progressive Rock
  (2152, 2052), -- Rock  ->  Proto-Punk
  (2152, 2059), -- Rock  ->  Psychedelic Rock
  (2152, 2066), -- Rock  ->  Pub Rock
  (2152, 2071), -- Rock  ->  Punk Blues
  (2152, 2073), -- Rock  ->  Punk Rock
  (2152, 2107), -- Rock  ->  Rap Rock
  (2152, 2127), -- Rock  ->  Reggae Rock
  (2152, 2153), -- Rock  ->  Rock & Roll
  (2152, 2155), -- Rock  ->  Rock andaluz
  (2152, 2156), -- Rock  ->  Rock andino
  (2152, 2160), -- Rock  ->  Rock Musical
  (2152, 2161), -- Rock  ->  Rock Opera
  (2152, 2185), -- Rock  ->  Roots Rock
  (2152, 2395), -- Rock  ->  Southern Rock
  (2152, 2442), -- Rock  ->  Sufi Rock
  (2152, 2449), -- Rock  ->  Surf Music
  (2152, 2466), -- Rock  ->  Symphonic Rock
  (2152, 2562), -- Rock  ->  Tolai Rock
  (2152, 2814), -- Rock  ->  Zolo
  (2153, 1254), -- Rock & Roll  ->  Indorock
  (2153, 2169), -- Rock & Roll  ->  Rockabilly
  (2153, 2647), -- Rock & Roll  ->  Twist
  (2169, 2061), -- Rockabilly  ->  Psychobilly
  (2176, 302), -- Romanian Folk Music  ->  Bocet
  (2176, 561), -- Romanian Folk Music  ->  Colinde
  (2176, 750), -- Romanian Folk Music  ->  Doină
  (2176, 1695), -- Romanian Folk Music  ->  Muzică lăutărească
  (2177, 1694), -- Romanian Music  ->  Muzică de mahala
  (2177, 2175), -- Romanian Music  ->  Romanian Etno Music
  (2177, 2176), -- Romanian Music  ->  Romanian Folk Music
  (2177, 2182), -- Romanian Music  ->  Romanţe
  (2180, 1083), -- Romanticism  ->  Grand opéra
  (2180, 1768), -- Romanticism  ->  New German School
  (2180, 2181), -- Romanticism  ->  Romantische Oper
  (2180, 2203), -- Romanticism  ->  Saint Petersburg School
  (2184, 784), -- Roots Reggae  ->  Dub Poetry
  (2185, 2455), -- Roots Rock  ->  Swamp Rock
  (2185, 2533), -- Roots Rock  ->  Tex-Mex
  (2187, 1098), -- Rumba cubana  ->  Guaguancó
  (2189, 2280), -- Rune Singing  ->  Seto leelo
  (2193, 168), -- Russian Music  ->  Avtorskaya pesnya
  (2193, 2191), -- Russian Music  ->  Russian Chanson
  (2193, 2192), -- Russian Music  ->  Russian Folk Music
  (2193, 2194), -- Russian Music  ->  Russian Romance
  (2195, 77), -- Ryukyuan Music  ->  Amami shimauta
  (2195, 1873), -- Ryukyuan Music  ->  Okinawan Music
  (2206, 2207), -- Salsa  ->  Salsa choke
  (2206, 2208), -- Salsa  ->  Salsa dura
  (2206, 2209), -- Salsa  ->  Salsa romántica
  (2206, 2554), -- Salsa  ->  Timba
  (2211, 235), -- Samba  ->  Batucada
  (2211, 321), -- Samba  ->  Bossa nova
  (2211, 1559), -- Samba  ->  Marchinha
  (2211, 1911), -- Samba  ->  Pagode
  (2211, 1928), -- Samba  ->  Partido alto
  (2211, 2212), -- Samba  ->  Samba de breque
  (2211, 2213), -- Samba  ->  Samba de gafieira
  (2211, 2214), -- Samba  ->  Samba de roda
  (2211, 2215), -- Samba  ->  Samba de terreiro
  (2211, 2218), -- Samba  ->  Samba-canção
  (2211, 2219), -- Samba  ->  Samba-choro
  (2211, 2220), -- Samba  ->  Samba-enredo
  (2211, 2221), -- Samba  ->  Samba-exaltação
  (2211, 2222), -- Samba  ->  Samba-jazz
  (2211, 2223), -- Samba  ->  Samba-joia
  (2211, 2225), -- Samba  ->  Samba-rock
  (2211, 2226), -- Samba  ->  Sambalanço
  (2225, 2217), -- Samba-rock  ->  Samba Soul
  (2233, 1118), -- San Francisco Sound  ->  Haight-Ashbury Scene
  (2239, 429), -- Sardinian Folk Music  ->  Cantu a chiterra
  (2239, 430), -- Sardinian Folk Music  ->  Cantu a tenore
  (2246, 1131), -- Scene  ->  Happy Rock
  (2247, 1211), -- Schlager  ->  Humppa
  (2247, 1474), -- Schlager  ->  Levenslied
  (2247, 2725), -- Schlager  ->  Volkstümliche Musik
  (2247, 2843), -- Schlager  ->  Partyschlager
  (2248, 528), -- Schottische  ->  Chotis madrileño
  (2252, 1963), -- Scottish Folk Music  ->  Pipe Band
  (2252, 2080), -- Scottish Folk Music  ->  Pìobaireachd
  (2252, 2250), -- Scottish Folk Music  ->  Scots Song
  (2252, 2251), -- Scottish Folk Music  ->  Scottish Country Dance Music
  (2252, 2295), -- Scottish Folk Music  ->  Shetland & Orkney Folk Music
  (2252, 2820), -- Scottish Folk Music  ->  Òrain Ghàidhlig
  (2254, 1143), -- Scouse House  ->  Hardbass
  (2255, 843), -- Screamo  ->  Emoviolence
  (2269, 216), -- Sephardic Music  ->  Baqashot
  (2269, 1448), -- Sephardic Music  ->  Ladino Folksong
  (2269, 1515), -- Sephardic Music  ->  Maftirim
  (2270, 2), -- Sequencer & Tracker  ->  16-bit
  (2270, 2576), -- Sequencer & Tracker  ->  Tracker Music
  (2272, 2273), -- Serenade  ->  Seresta
  (2274, 1267), -- Serialism  ->  Integral Serialism
  (2276, 2114), -- Sertanejo  ->  Rasqueado
  (2276, 2277), -- Sertanejo  ->  Sertanejo de raiz
  (2276, 2278), -- Sertanejo  ->  Sertanejo romântico
  (2276, 2279), -- Sertanejo  ->  Sertanejo universitário
  (2277, 1645), -- Sertanejo de raiz  ->  Moda de viola
  (2279, 50), -- Sertanejo universitário  ->  Agronejo
  (2279, 130), -- Sertanejo universitário  ->  Arrocha sertanejo
  (2279, 993), -- Sertanejo universitário  ->  Funknejo
  (2284, 1534), -- Seychelles & Mascarene Islands Music  ->  Maloya
  (2284, 1674), -- Seychelles & Mascarene Islands Music  ->  Moutya
  (2284, 2236), -- Seychelles & Mascarene Islands Music  ->  Santé engagé
  (2284, 2473), -- Seychelles & Mascarene Islands Music  ->  Séga
  (2285, 1519), -- Shaabi  ->  Mahraganat
  (2285, 2601), -- Shaabi  ->  Trap shaabi
  (2296, 55), -- Shibuya-kei  ->  Akishibu-kei
  (2296, 1955), -- Shibuya-kei  ->  Picopop
  (2304, 514), -- Shona Music  ->  Chimurenga
  (2304, 2303), -- Shona Music  ->  Shona Mbira Music
  (2310, 594), -- Sierreño  ->  Corrido tumbado
  (2317, 168), -- Singer-Songwriter  ->  Avtorskaya pesnya
  (2317, 432), -- Singer-Songwriter  ->  Canzone d'autore
  (2317, 488), -- Singer-Songwriter  ->  Chanson à texte
  (2317, 870), -- Singer-Songwriter  ->  Euskal kantagintza berria
  (2317, 1407), -- Singer-Songwriter  ->  Kleinkunst
  (2317, 1477), -- Singer-Songwriter  ->  Liedermacher
  (2317, 1706), -- Singer-Songwriter  ->  Música de intervenção
  (2317, 1833), -- Singer-Songwriter  ->  Nova cançó
  (2317, 1849), -- Singer-Songwriter  ->  Nueva canción
  (2317, 1862), -- Singer-Songwriter  ->  Nòva cançon
  (2317, 1975), -- Singer-Songwriter  ->  Poezja śpiewana
  (2317, 2617), -- Singer-Songwriter  ->  Trova
  (2319, 2237), -- Sinhalese Folk Music  ->  Sarala gee
  (2322, 489), -- Sizhu Music  ->  Chaozhou xianshi
  (2322, 1100), -- Sizhu Music  ->  Guangdong yinyue
  (2322, 1330), -- Sizhu Music  ->  Jiangnan sizhu
  (2322, 1717), -- Sizhu Music  ->  Nanyin
  (2323, 3), -- Ska  ->  2 Tone
  (2323, 1295), -- Ska  ->  Jamaican Ska
  (2323, 1782), -- Ska  ->  New Tone
  (2323, 2421), -- Ska  ->  Spouge
  (2323, 2546), -- Ska  ->  Third Wave Ska
  (2324, 2325), -- Ska Punk  ->  Skacore
  (2325, 612), -- Skacore  ->  Crack Rock Steady
  (2334, 2301), -- Slacker Rock  ->  Shitgaze
  (2338, 255), -- Slavic Folk Music  ->  Belarusian Folk Music
  (2338, 320), -- Slavic Folk Music  ->  Bosnian Folk Music
  (2338, 386), -- Slavic Folk Music  ->  Bulgarian Folk Music
  (2338, 617), -- Slavic Folk Music  ->  Croatian Folk Music
  (2338, 655), -- Slavic Folk Music  ->  Czech Folk Music
  (2338, 1034), -- Slavic Folk Music  ->  Ganga
  (2338, 1073), -- Slavic Folk Music  ->  Goral Music
  (2338, 1509), -- Slavic Folk Music  ->  Macedonian Folk Music
  (2338, 1657), -- Slavic Folk Music  ->  Montenegrin Folk Music
  (2338, 1663), -- Slavic Folk Music  ->  Moravian Folk Music
  (2338, 1977), -- Slavic Folk Music  ->  Polish Folk Music
  (2338, 2192), -- Slavic Folk Music  ->  Russian Folk Music
  (2338, 2271), -- Slavic Folk Music  ->  Serbian Folk Music
  (2338, 2341), -- Slavic Folk Music  ->  Slovak Folk Music
  (2338, 2342), -- Slavic Folk Music  ->  Slovenian Folk Music
  (2338, 2425), -- Slavic Folk Music  ->  Starogradska muzika
  (2338, 2663), -- Slavic Folk Music  ->  Ukrainian Folk Music
  (2342, 1719), -- Slovenian Folk Music  ->  Narodno zabavna glasba
  (2345, 154), -- Sludge Metal  ->  Atmospheric Sludge Metal
  (2350, 225), -- Soca  ->  Bashment Soca
  (2350, 537), -- Soca  ->  Chutney Soca
  (2350, 715), -- Soca  ->  Dennery Segment
  (2350, 2027), -- Soca  ->  Power Soca
  (2350, 2109), -- Soca  ->  Rapso
  (2351, 2612), -- Soft Rock  ->  Tropical Rock
  (2351, 2775), -- Soft Rock  ->  Yacht Rock
  (2355, 258), -- Somali Music  ->  Belwo
  (2355, 725), -- Somali Music  ->  Dhaanto
  (2355, 2082), -- Somali Music  ->  Qaraami
  (2357, 308), -- Son cubano  ->  Bolero son
  (2357, 2362), -- Son cubano  ->  Son montuno
  (2370, 1439), -- Soukous  ->  Kwassa kwassa
  (2371, 501), -- Soul  ->  Chicago Soul
  (2371, 606), -- Soul  ->  Country Soul
  (2371, 708), -- Soul  ->  Deep Soul
  (2371, 1465), -- Soul  ->  Latin Soul
  (2371, 1740), -- Soul  ->  Neo-Soul
  (2371, 1949), -- Soul  ->  Philly Soul
  (2371, 2000), -- Soul  ->  Pop Soul
  (2371, 2050), -- Soul  ->  Progressive Soul
  (2371, 2060), -- Soul  ->  Psychedelic Soul
  (2371, 2348), -- Soul  ->  Smooth Soul
  (2371, 2396), -- Soul  ->  Southern Soul
  (2375, 851), -- Sound Collage  ->  Epic Collage
  (2375, 1616), -- Sound Collage  ->  Micromontage
  (2376, 234), -- Sound Effects  ->  Battle Record
  (2376, 278), -- Sound Effects  ->  Binaural Beats
  (2376, 363), -- Sound Effects  ->  Broadband Noise
  (2379, 904), -- Soundtrack  ->  Film Soundtrack
  (2379, 1475), -- Soundtrack  ->  Library Music
  (2379, 2527), -- Soundtrack  ->  Television Music
  (2379, 2702), -- Soundtrack  ->  Video Game Music
  (2380, 60), -- South American Music  ->  Aleke
  (2380, 123), -- South American Music  ->  Argentine Music
  (2380, 166), -- South American Music  ->  Avanzada
  (2380, 183), -- South American Music  ->  Bailecito
  (2380, 185), -- South American Music  ->  Baithak gana
  (2380, 207), -- South American Music  ->  Bambuco
  (2380, 333), -- South American Music  ->  Brazilian Music
  (2380, 387), -- South American Music  ->  Bullerengue
  (2380, 406), -- South American Music  ->  Calipso venezolano
  (2380, 416), -- South American Music  ->  Candombe beat
  (2380, 440), -- South American Music  ->  Caporal
  (2380, 447), -- South American Music  ->  Carnaval cruceño
  (2380, 450), -- South American Music  ->  Carranga
  (2380, 468), -- South American Music  ->  Chacarera
  (2380, 471), -- South American Music  ->  Chamamé
  (2380, 479), -- South American Music  ->  Champeta
  (2380, 506), -- South American Music  ->  Chilean Music
  (2380, 535), -- South American Music  ->  Chuntunqui romántico
  (2380, 580), -- South American Music  ->  Conjunto andino
  (2380, 631), -- South American Music  ->  Cueca
  (2380, 637), -- South American Music  ->  Cumbia colombiana
  (2380, 651), -- South American Music  ->  Currulao
  (2380, 1018), -- South American Music  ->  Gaita zuliana
  (2380, 1104), -- South American Music  ->  Guarania
  (2380, 1247), -- South American Music  ->  Indigenous Andean Music
  (2380, 1340), -- South American Music  ->  Joropo
  (2380, 1380), -- South American Music  ->  Kaseko
  (2380, 1525), -- South American Music  ->  Malagueña venezolana
  (2380, 1552), -- South American Music  ->  Mapuche Folk Music
  (2380, 1682), -- South American Music  ->  Muliza
  (2380, 1709), -- South American Music  ->  Música llanera
  (2380, 1877), -- South American Music  ->  Onda nueva
  (2380, 1925), -- South American Music  ->  Paramaribop
  (2380, 1930), -- South American Music  ->  Pasillo
  (2380, 1933), -- South American Music  ->  Payada
  (2380, 1942), -- South American Music  ->  Peruvian Music
  (2380, 1982), -- South American Music  ->  Polka paraguaya
  (2380, 2006), -- South American Music  ->  Porro
  (2380, 2144), -- South American Music  ->  Rioplatense Music
  (2380, 2156), -- South American Music  ->  Rock andino
  (2380, 2207), -- South American Music  ->  Salsa choke
  (2380, 2244), -- South American Music  ->  Saya
  (2380, 2496), -- South American Music  ->  Taquirari
  (2380, 2523), -- South American Music  ->  Tecnomerengue
  (2380, 2687), -- South American Music  ->  Vallenato
  (2380, 2689), -- South American Music  ->  Vals venezolano
  (2380, 2779), -- South American Music  ->  Yaraví
  (2380, 2794), -- South American Music  ->  Zamacueca
  (2380, 2795), -- South American Music  ->  Zamba
  (2381, 446), -- South Asian Classical Music  ->  Carnatic Classical Music
  (2381, 1181), -- South Asian Classical Music  ->  Hindustani Classical Music
  (2381, 1870), -- South Asian Classical Music  ->  Odissi Classical Music
  (2382, 146), -- South Asian Folk Music  ->  Assamese Folk Music
  (2382, 261), -- South Asian Folk Music  ->  Bengali Folk Music
  (2382, 270), -- South Asian Folk Music  ->  Bhojpuri Folk Music
  (2382, 303), -- South Asian Folk Music  ->  Boduberu
  (2382, 392), -- South Asian Folk Music  ->  Burushaski Folk Music
  (2382, 1109), -- South Asian Folk Music  ->  Gujarati Folk Music
  (2382, 1371), -- South Asian Folk Music  ->  Kannada Folk Music
  (2382, 1402), -- South Asian Folk Music  ->  Kirtan
  (2382, 1530), -- South Asian Folk Music  ->  Malayali Folk Music
  (2382, 1556), -- South Asian Folk Music  ->  Marathi Folk Music
  (2382, 1752), -- South Asian Folk Music  ->  Nepali lok geet
  (2382, 1869), -- South Asian Folk Music  ->  Odia Folk Music
  (2382, 1929), -- South Asian Folk Music  ->  Pashto Folk Music
  (2382, 2069), -- South Asian Folk Music  ->  Punjabi Folk Music
  (2382, 2104), -- South Asian Folk Music  ->  Rajasthani Folk Music
  (2382, 2319), -- South Asian Folk Music  ->  Sinhalese Folk Music
  (2382, 2489), -- South Asian Folk Music  ->  Tamil Folk Music
  (2382, 2528), -- South Asian Folk Music  ->  Telugu Folk Music
  (2383, 28), -- South Asian Music  ->  Adhunik geet
  (2383, 182), -- South Asian Music  ->  Baila
  (2383, 201), -- South Asian Music  ->  Balochi Music
  (2383, 268), -- South Asian Music  ->  Bhajan
  (2383, 269), -- South Asian Music  ->  Bhangra
  (2383, 710), -- South Asian Music  ->  Dek Bass
  (2383, 726), -- South Asian Music  ->  Dhol tasha
  (2383, 905), -- South Asian Music  ->  Filmi
  (2383, 1013), -- South Asian Music  ->  Gaana
  (2383, 1041), -- South Asian Music  ->  Garba
  (2383, 1056), -- South Asian Music  ->  Ginan
  (2383, 1068), -- South Asian Music  ->  Goan Music
  (2383, 1237), -- South Asian Music  ->  Indian Pop
  (2383, 1251), -- South Asian Music  ->  Indo Jazz
  (2383, 1791), -- South Asian Music  ->  Newa Music
  (2383, 1992), -- South Asian Music  ->  Pop Ghazal
  (2383, 2142), -- South Asian Music  ->  Rigsar
  (2383, 2314), -- South Asian Music  ->  Sindhi Music
  (2383, 2381), -- South Asian Music  ->  South Asian Classical Music
  (2383, 2382), -- South Asian Music  ->  South Asian Folk Music
  (2383, 2442), -- South Asian Music  ->  Sufi Rock
  (2383, 2443), -- South Asian Music  ->  Sufiana kalam
  (2383, 2502), -- South Asian Music  ->  Tarz
  (2383, 2699), -- South Asian Music  ->  Vedic Chant
  (2385, 389), -- Southeast Asian Classical Music  ->  Burmese Classical Music
  (2385, 1022), -- Southeast Asian Classical Music  ->  Gamelan
  (2385, 1358), -- Southeast Asian Classical Music  ->  Kacapi suling
  (2385, 1364), -- Southeast Asian Classical Music  ->  Kakawin
  (2385, 1431), -- Southeast Asian Classical Music  ->  Kulintang
  (2385, 1518), -- Southeast Asian Classical Music  ->  Mahori
  (2385, 1526), -- Southeast Asian Classical Music  ->  Malay Classical Music
  (2385, 1961), -- Southeast Asian Classical Music  ->  Pinpeat
  (2385, 2210), -- Southeast Asian Classical Music  ->  Saluang klasik
  (2385, 2482), -- Southeast Asian Classical Music  ->  Talempong
  (2385, 2529), -- Southeast Asian Classical Music  ->  Tembang Sunda Cianjuran
  (2385, 2536), -- Southeast Asian Classical Music  ->  Thai Classical Music
  (2386, 192), -- Southeast Asian Folk Music  ->  Balitaw
  (2386, 205), -- Southeast Asian Folk Music  ->  Bamar Folk Music
  (2386, 1071), -- Southeast Asian Folk Music  ->  Gondang
  (2386, 1132), -- Southeast Asian Folk Music  ->  Harana
  (2386, 1191), -- Southeast Asian Folk Music  ->  Hmong Folk Music
  (2386, 1395), -- Southeast Asian Folk Music  ->  Khmer Folk Music
  (2386, 1427), -- Southeast Asian Folk Music  ->  Kuda kepang
  (2386, 1453), -- Southeast Asian Folk Music  ->  Lao Folk Music
  (2386, 1527), -- Southeast Asian Folk Music  ->  Malay Folk Music
  (2386, 1945), -- Southeast Asian Folk Music  ->  Philippine Rondalla
  (2386, 2108), -- Southeast Asian Folk Music  ->  Rapai dabõih
  (2386, 2500), -- Southeast Asian Folk Music  ->  Tarawangsa
  (2386, 2537), -- Southeast Asian Folk Music  ->  Thai Folk Music
  (2386, 2704), -- Southeast Asian Folk Music  ->  Vietnamese Folk Music
  (2387, 206), -- Southeast Asian Music  ->  Bamar Music
  (2387, 1179), -- Southeast Asian Music  ->  Hill Tribe Music
  (2387, 1253), -- Southeast Asian Music  ->  Indonesian Music
  (2387, 1396), -- Southeast Asian Music  ->  Khmer Music
  (2387, 1529), -- Southeast Asian Music  ->  Malay Music
  (2387, 1651), -- Southeast Asian Music  ->  Molam
  (2387, 1944), -- Southeast Asian Music  ->  Philippine Music
  (2387, 2385), -- Southeast Asian Music  ->  Southeast Asian Classical Music
  (2387, 2386), -- Southeast Asian Music  ->  Southeast Asian Folk Music
  (2387, 2429), -- Southeast Asian Music  ->  Stereo
  (2387, 2538), -- Southeast Asian Music  ->  Thai Music
  (2387, 2705), -- Southeast Asian Music  ->  Vietnamese Music
  (2387, 2770), -- Southeast Asian Music  ->  Xinyao
  (2388, 527), -- Southeastern Brazilian Music  ->  Choro
  (2388, 1338), -- Southeastern Brazilian Music  ->  Jongo
  (2388, 1559), -- Southeastern Brazilian Music  ->  Marchinha
  (2388, 1573), -- Southeastern Brazilian Music  ->  Maxixe
  (2388, 1911), -- Southeastern Brazilian Music  ->  Pagode
  (2388, 1928), -- Southeastern Brazilian Music  ->  Partido alto
  (2388, 2212), -- Southeastern Brazilian Music  ->  Samba de breque
  (2388, 2213), -- Southeastern Brazilian Music  ->  Samba de gafieira
  (2388, 2215), -- Southeastern Brazilian Music  ->  Samba de terreiro
  (2388, 2220), -- Southeastern Brazilian Music  ->  Samba-enredo
  (2388, 2273), -- Southeastern Brazilian Music  ->  Seresta
  (2388, 2488), -- Southeastern Brazilian Music  ->  Tamborzão
  (2389, 35), -- Southern African Folk Music  ->  Afrikaner Folk Music
  (2389, 1397), -- Southern African Folk Music  ->  Khoisan Folk Music
  (2389, 1794), -- Southern African Folk Music  ->  Nguni Folk Music
  (2389, 2369), -- Southern African Folk Music  ->  Sotho-Tswana Folk Music
  (2390, 78), -- Southern African Music  ->  Amapiano
  (2390, 384), -- Southern African Music  ->  Bulawayo Jazz
  (2390, 437), -- Southern African Music  ->  Cape Jazz
  (2390, 883), -- Southern African Music  ->  Famo
  (2390, 1082), -- Southern African Music  ->  Gqom
  (2390, 1275), -- Southern African Music  ->  Isicathamiya
  (2390, 1335), -- Southern African Music  ->  Jit
  (2390, 1438), -- Southern African Music  ->  Kwaito
  (2390, 1554), -- Southern African Music  ->  Marabi
  (2390, 1567), -- Southern African Music  ->  Maskandi
  (2390, 1581), -- Southern African Music  ->  Mbube
  (2390, 1673), -- Southern African Music  ->  Motswako
  (2390, 2289), -- Southern African Music  ->  Shangaan Electro
  (2390, 2304), -- Southern African Music  ->  Shona Music
  (2390, 2389), -- Southern African Music  ->  Southern African Folk Music
  (2390, 2445), -- Southern African Music  ->  Sungura
  (2390, 2572), -- Southern African Music  ->  Township Bubblegum
  (2390, 2573), -- Southern African Music  ->  Township Jive
  (2390, 2623), -- Southern African Music  ->  Tsonga Disco
  (2391, 213), -- Southern Brazilian Music  ->  Bandinha
  (2391, 1708), -- Southern Brazilian Music  ->  Música gaúcha
  (2393, 2384), -- Southern Hip Hop  ->  South Florida SoundCloud Rap
  (2402, 2403), -- Space Rock  ->  Space Rock Revival
  (2404, 761), -- Spacesynth  ->  Doskpop
  (2406, 425), -- Spanish Classical Music  ->  Canto mozárabe
  (2406, 2797), -- Spanish Classical Music  ->  Zarzuela
  (2407, 105), -- Spanish Folk Music  ->  Andalusian Folk Music
  (2407, 122), -- Spanish Folk Music  ->  Aragonese Folk Music
  (2407, 149), -- Spanish Folk Music  ->  Asturian Folk Music
  (2407, 413), -- Spanish Folk Music  ->  Canarian Folk Music
  (2407, 528), -- Spanish Folk Music  ->  Chotis madrileño
  (2407, 589), -- Spanish Folk Music  ->  Copla
  (2407, 650), -- Spanish Folk Music  ->  Cuplé
  (2407, 1019), -- Spanish Folk Music  ->  Galician Folk Music
  (2407, 1707), -- Spanish Folk Music  ->  Música festera
  (2407, 1931), -- Spanish Folk Music  ->  Pasodoble
  (2407, 2686), -- Spanish Folk Music  ->  Valencian Folk Music
  (2408, 307), -- Spanish Music  ->  Bolero español
  (2408, 909), -- Spanish Music  ->  Flamenco
  (2408, 912), -- Spanish Music  ->  Flamenco Pop
  (2408, 1851), -- Spanish Music  ->  Nueva canción española
  (2408, 2155), -- Spanish Music  ->  Rock andaluz
  (2408, 2186), -- Spanish Music  ->  Rumba catalana
  (2408, 2406), -- Spanish Music  ->  Spanish Classical Music
  (2408, 2407), -- Spanish Music  ->  Spanish Folk Music
  (2408, 2524), -- Spanish Music  ->  Tecnorumba
  (2410, 2275), -- Speeches  ->  Sermons
  (2414, 878), -- Speedcore  ->  Extratone
  (2414, 2419), -- Speedcore  ->  Splittercore
  (2415, 572), -- Spiritual  ->  Concert Spiritual
  (2420, 881), -- Spoken Word  ->  Fairy Tale
  (2420, 928), -- Spoken Word  ->  Folktales
  (2420, 1107), -- Spoken Word  ->  Guided Meditation
  (2420, 1268), -- Spoken Word  ->  Interview
  (2420, 1470), -- Spoken Word  ->  Lectures
  (2420, 1974), -- Spoken Word  ->  Poetry
  (2420, 2094), -- Spoken Word  ->  Radio Drama
  (2420, 2410), -- Spoken Word  ->  Speeches
  (2420, 2423), -- Spoken Word  ->  Stand-Up Comedy
  (2425, 2823), -- Starogradska muzika  ->  Čalgija
  (2436, 1422), -- Straight Edge  ->  Krishnacore
  (2436, 2700), -- Straight Edge  ->  Vegan Straight Edge
  (2436, 2787), -- Straight Edge  ->  Youth Crew
  (2441, 214), -- Sufi Music  ->  Banga
  (2441, 1333), -- Sufi Music  ->  Jilala Music
  (2441, 1360), -- Sufi Music  ->  Kafi
  (2441, 1550), -- Sufi Music  ->  Manzuma
  (2441, 2084), -- Sufi Music  ->  Qawwali
  (2441, 2442), -- Sufi Music  ->  Sufi Rock
  (2441, 2443), -- Sufi Music  ->  Sufiana kalam
  (2441, 2635), -- Sufi Music  ->  Turkish Mevlevi Music
  (2444, 1026), -- Sundanese Music  ->  Gamelan degung
  (2444, 1292), -- Sundanese Music  ->  Jaipongan
  (2444, 1358), -- Sundanese Music  ->  Kacapi suling
  (2444, 1391), -- Sundanese Music  ->  Ketuk tilu
  (2444, 1409), -- Sundanese Music  ->  Kliningan
  (2444, 2001), -- Sundanese Music  ->  Pop Sunda
  (2444, 2500), -- Sundanese Music  ->  Tarawangsa
  (2444, 2529), -- Sundanese Music  ->  Tembang Sunda Cianjuran
  (2449, 1206), -- Surf Music  ->  Hot Rod Music
  (2449, 1243), -- Surf Music  ->  Indie Surf
  (2449, 2450), -- Surf Music  ->  Surf Punk
  (2449, 2451), -- Surf Music  ->  Surf Rock
  (2449, 2719), -- Surf Music  ->  Vocal Surf
  (2451, 834), -- Surf Rock  ->  Eleki
  (2451, 2117), -- Surf Rock  ->  Rautalanka
  (2451, 2761), -- Surf Rock  ->  Wong shadow
  (2457, 1123), -- Swedish Folk Music  ->  Hambo
  (2459, 2461), -- Swing  ->  Swing Revival
  (2467, 526), -- Symphony  ->  Choral Symphony
  (2467, 2315), -- Symphony  ->  Sinfonia concertante
  (2468, 1637), -- Synth Funk  ->  Minneapolis Sound
  (2470, 1008), -- Synthpop  ->  Futurepop
  (2470, 1988), -- Synthpop  ->  Pon-chak disco
  (2470, 2516), -- Synthpop  ->  Techno kayō
  (2471, 510), -- Synthwave  ->  Chillsynth
  (2471, 689), -- Synthwave  ->  Darksynth
  (2471, 768), -- Synthwave  ->  Dreamwave
  (2471, 1902), -- Synthwave  ->  Outrun
  (2473, 2264), -- Séga  ->  Seggae
  (2473, 2588), -- Séga  ->  Traditional Séga
  (2475, 672), -- Sōkyoku  ->  Danmono
  (2475, 1433), -- Sōkyoku  ->  Kumiuta
  (2477, 2849), -- Taarab  ->  M'godro
  (2478, 1), -- Tahitian Music  ->  'Ote'a
  (2489, 2677), -- Tamil Folk Music  ->  Urumi melam
  (2491, 907), -- Tango  ->  Finnish Tango
  (2491, 2492), -- Tango  ->  Tango Nuevo
  (2499, 1968), -- Tarantella  ->  Pizzica
  (2499, 2490), -- Tarantella  ->  Tammurriata
  (2510, 709), -- Tech House  ->  Deep Tech
  (2510, 2183), -- Tech House  ->  Rominimal
  (2512, 741), -- Technical Death Metal  ->  Dissonant Death Metal
  (2514, 20), -- Techno  ->  Acid Techno
  (2514, 88), -- Techno  ->  Ambient Techno
  (2514, 257), -- Techno  ->  Belgian Techno
  (2514, 295), -- Techno  ->  Bleep Techno
  (2514, 722), -- Techno  ->  Detroit Techno
  (2514, 957), -- Techno  ->  Freetekno
  (2514, 1139), -- Techno  ->  Hard Techno
  (2514, 1149), -- Techno  ->  Hardgroove Techno
  (2514, 1262), -- Techno  ->  Industrial Techno
  (2514, 1597), -- Techno  ->  Melodic Techno
  (2514, 1634), -- Techno  ->  Minimal Techno
  (2514, 1934), -- Techno  ->  Peak Time Techno
  (2514, 2505), -- Techno  ->  TBM
  (2514, 2763), -- Techno  ->  Wonky Techno
  (2514, 2827), -- Techno  ->  Berlin Techno
  (2515, 442), -- Techno Bass  ->  Car Audio Bass
  (2521, 343), -- Tecnobrega  ->  Brega funk
  (2521, 2522), -- Tecnobrega  ->  Tecnofunk
  (2528, 391), -- Telugu Folk Music  ->  Burrakatha
  (2534, 27), -- Texan Music  ->  Acoustic Texas Blues
  (2534, 818), -- Texan Music  ->  Electric Texas Blues
  (2534, 2526), -- Texan Music  ->  Tejano Music
  (2534, 2533), -- Texan Music  ->  Tex-Mex
  (2536, 930), -- Thai Classical Music  ->  Fon leb
  (2536, 1398), -- Thai Classical Music  ->  Khrueang sai
  (2536, 1964), -- Thai Classical Music  ->  Piphat
  (2537, 930), -- Thai Folk Music  ->  Fon leb
  (2538, 1502), -- Thai Music  ->  Luk krung
  (2538, 1503), -- Thai Music  ->  Luk thung
  (2538, 1652), -- Thai Music  ->  Molam sing
  (2538, 1950), -- Thai Music  ->  Phleng phuea chiwit
  (2538, 2536), -- Thai Music  ->  Thai Classical Music
  (2538, 2537), -- Thai Music  ->  Thai Folk Music
  (2538, 2761), -- Thai Music  ->  Wong shadow
  (2546, 2324), -- Third Wave Ska  ->  Ska Punk
  (2547, 619), -- Thrash Metal  ->  Crossover Thrash
  (2547, 2513), -- Thrash Metal  ->  Technical Thrash Metal
  (2548, 2029), -- Thrashcore  ->  Powerviolence
  (2551, 540), -- Tibetan Music  ->  Chöd
  (2551, 2550), -- Tibetan Music  ->  Tibetan Buddhist Chant
  (2551, 2806), -- Tibetan Music  ->  Zhabdro gorgom
  (2576, 95), -- Tracker Music  ->  Amigacore
  (2576, 714), -- Tracker Music  ->  Demostyle
  (2580, 299), -- Traditional Bluegrass  ->  Bluegrass Gospel
  (2582, 553), -- Traditional Country  ->  Close Harmony
  (2582, 602), -- Traditional Country  ->  Country Gospel
  (2582, 607), -- Traditional Country  ->  Country Yodeling
  (2582, 2580), -- Traditional Country  ->  Traditional Bluegrass
  (2583, 852), -- Traditional Doom Metal  ->  Epic Doom Metal
  (2584, 33), -- Traditional Folk Music  ->  African Folk Music
  (2584, 91), -- Traditional Folk Music  ->  American Folk Music
  (2584, 118), -- Traditional Folk Music  ->  Arabic Folk Music
  (2584, 157), -- Traditional Folk Music  ->  Australian Folk Music
  (2584, 240), -- Traditional Folk Music  ->  Bayawan
  (2584, 332), -- Traditional Folk Music  ->  Brazilian Folk Music
  (2584, 411), -- Traditional Folk Music  ->  Canadian Folk Music
  (2584, 443), -- Traditional Folk Music  ->  Caribbean Folk Music
  (2584, 454), -- Traditional Folk Music  ->  Caucasian Folk Music
  (2584, 534), -- Traditional Folk Music  ->  Chukchi Folk Music
  (2584, 772), -- Traditional Folk Music  ->  Drinking Song
  (2584, 803), -- Traditional Folk Music  ->  East Asian Folk Music
  (2584, 866), -- Traditional Folk Music  ->  European Folk Music
  (2584, 932), -- Traditional Folk Music  ->  Football Chant
  (2584, 1164), -- Traditional Folk Music  ->  Hazara Folk Music
  (2584, 1188), -- Traditional Folk Music  ->  Hispanic American Folk Music
  (2584, 1246), -- Traditional Folk Music  ->  Indigenous American Traditional Music
  (2584, 1248), -- Traditional Folk Music  ->  Indigenous Australian Traditional Music
  (2584, 1257), -- Traditional Folk Music  ->  Industrial Folk Song
  (2584, 1448), -- Traditional Folk Music  ->  Ladino Folksong
  (2584, 1864), -- Traditional Folk Music  ->  Ob-Ugric Folk Music
  (2584, 1933), -- Traditional Folk Music  ->  Payada
  (2584, 2229), -- Traditional Folk Music  ->  Samoyedic Folk Music
  (2584, 2382), -- Traditional Folk Music  ->  South Asian Folk Music
  (2584, 2386), -- Traditional Folk Music  ->  Southeast Asian Folk Music
  (2584, 2743), -- Traditional Folk Music  ->  West Asian Folk Music
  (2584, 2764), -- Traditional Folk Music  ->  Work Song
  (2584, 2784), -- Traditional Folk Music  ->  Yodeling
  (2586, 355), -- Traditional Pop  ->  British Dance Band
  (2586, 1658), -- Traditional Pop  ->  Mood kayō
  (2586, 2182), -- Traditional Pop  ->  Romanţe
  (2586, 2424), -- Traditional Pop  ->  Standards
  (2586, 2556), -- Traditional Pop  ->  Tin Pan Alley
  (2588, 2474), -- Traditional Séga  ->  Séga tambour
  (2592, 21), -- Trance  ->  Acid Trance
  (2592, 275), -- Trance  ->  Big Room Trance
  (2592, 766), -- Trance  ->  Dream Trance
  (2592, 824), -- Trance  ->  Electro Trance
  (2592, 861), -- Trance  ->  Euro Trance
  (2592, 1140), -- Trance  ->  Hard Trance
  (2592, 1174), -- Trance  ->  Hi-Tech Full-On
  (2592, 1226), -- Trance  ->  Ibiza Trance
  (2592, 1840), -- Trance  ->  NRG
  (2592, 2051), -- Trance  ->  Progressive Trance
  (2592, 2065), -- Trance  ->  Psytrance
  (2592, 2511), -- Trance  ->  Tech Trance
  (2592, 2593), -- Trance  ->  Trance 2.0
  (2592, 2670), -- Trance  ->  Uplifting Trance
  (2592, 2720), -- Trance  ->  Vocal Trance
  (2596, 495), -- Trap  ->  Chicago Drill
  (2596, 949), -- Trap  ->  Free Car Music
  (2596, 1010), -- Trap  ->  Futuristic Swag
  (2596, 1770), -- Trap  ->  New Jazz
  (2596, 1804), -- Trap  ->  No Melody
  (2596, 1971), -- Trap  ->  Plugg
  (2596, 2096), -- Trap  ->  Rage
  (2596, 2112), -- Trap  ->  Rare Phonk
  (2596, 2124), -- Trap  ->  Regalia
  (2596, 2597), -- Trap  ->  Trap [EDM]
  (2596, 2599), -- Trap  ->  Trap latino
  (2596, 2600), -- Trap  ->  Trap Metal
  (2596, 2602), -- Trap  ->  Trap Soul
  (2596, 2605), -- Trap  ->  Tread
  (2596, 2831), -- Trap  ->  Detroit Trap
  (2597, 892), -- Trap [EDM]  ->  Festival Trap
  (2597, 1141), -- Trap [EDM]  ->  Hard Trap
  (2597, 1166), -- Trap [EDM]  ->  Heaven Trap
  (2597, 1215), -- Trap [EDM]  ->  Hybrid Trap
  (2597, 2646), -- Trap [EDM]  ->  Twerk
  (2608, 1102), -- Tribal House  ->  Guaracha [EDM]
  (2616, 1988), -- Trot  ->  Pon-chak disco
  (2616, 2268), -- Trot  ->  Semi-Trot
  (2617, 1856), -- Trova  ->  Nueva trova
  (2625, 2481), -- Tuareg Music  ->  Takamba
  (2625, 2557), -- Tuareg Music  ->  Tishoumaren
  (2631, 70), -- Turkic-Mongolic Music  ->  Altai Music
  (2631, 224), -- Turkic-Mongolic Music  ->  Bashkir Folk Music
  (2631, 467), -- Turkic-Mongolic Music  ->  Central Asian Throat Singing
  (2631, 1378), -- Turkic-Mongolic Music  ->  Karakalpak Traditional Music
  (2631, 1392), -- Turkic-Mongolic Music  ->  Khakas Traditional Music
  (2631, 1442), -- Turkic-Mongolic Music  ->  Kyrgyz Traditional Music
  (2631, 1653), -- Turkic-Mongolic Music  ->  Mongolian Music
  (2631, 2204), -- Turkic-Mongolic Music  ->  Sakha Traditional Music
  (2633, 2635), -- Turkish Classical Music  ->  Turkish Mevlevi Music
  (2634, 2632), -- Turkish Folk Music  ->  Turkish Black Sea Region Folk Music
  (2634, 2683), -- Turkish Folk Music  ->  Uzun Hava
  (2634, 2805), -- Turkish Folk Music  ->  Zeybek
  (2636, 97), -- Turkish Music  ->  Anatolian Rock
  (2636, 114), -- Turkish Music  ->  Arabesk
  (2636, 888), -- Turkish Music  ->  Fantezi
  (2636, 1374), -- Turkish Music  ->  Kanto
  (2636, 1900), -- Turkish Music  ->  Ottoman Military Music
  (2636, 2633), -- Turkish Music  ->  Turkish Classical Music
  (2636, 2634), -- Turkish Music  ->  Turkish Folk Music
  (2636, 2637), -- Turkish Music  ->  Turkish Pop
  (2636, 2822), -- Turkish Music  ->  Özgün Müzik
  (2644, 630), -- Twee Pop  ->  Cuddlecore
  (2656, 4), -- UK Garage  ->  2-Step
  (2656, 228), -- UK Garage  ->  Bassline
  (2656, 340), -- UK Garage  ->  Breakstep
  (2656, 682), -- UK Garage  ->  Dark Garage
  (2656, 1004), -- UK Garage  ->  Future Garage
  (2656, 2411), -- UK Garage  ->  Speed Garage
  (2657, 2254), -- UK Hard House  ->  Scouse House
  (2657, 2412), -- UK Hard House  ->  Speed House
  (2658, 1002), -- UK Hardcore  ->  Future Core
  (2658, 2028), -- UK Hardcore  ->  Powerstomp
  (2663, 789), -- Ukrainian Folk Music  ->  Duma
  (2663, 1213), -- Ukrainian Folk Music  ->  Hutsul Folk Music
  (2668, 87), -- Uncategorised  ->  Ambient Pop
  (2668, 145), -- Uncategorised  ->  ASMR
  (2668, 155), -- Uncategorised  ->  Audio Documentary
  (2668, 248), -- Uncategorised  ->  Beatboxing
  (2668, 383), -- Uncategorised  ->  Bugle Call
  (2668, 505), -- Uncategorised  ->  Children's Music
  (2668, 563), -- Uncategorised  ->  Comedy
  (2668, 571), -- Uncategorised  ->  Concert Band
  (2668, 678), -- Uncategorised  ->  Dark Cabaret
  (2668, 690), -- Uncategorised  ->  Darkwave
  (2668, 718), -- Uncategorised  ->  Descriptor
  (2668, 896), -- Uncategorised  ->  Field Recordings
  (2668, 1127), -- Uncategorised  ->  Hanmai
  (2668, 1161), -- Uncategorised  ->  Hauntology
  (2668, 1216), -- Uncategorised  ->  Hymn
  (2668, 1334), -- Uncategorised  ->  Jingles
  (2668, 1547), -- Uncategorised  ->  Mantra
  (2668, 1557), -- Uncategorised  ->  March
  (2668, 1558), -- Uncategorised  ->  Marching Band
  (2668, 1566), -- Uncategorised  ->  Mashup
  (2668, 1583), -- Uncategorised  ->  Mechanical Music
  (2668, 1837), -- Uncategorised  ->  Novelty
  (2668, 1927), -- Uncategorised  ->  Parlour Music
  (2668, 2199), -- Uncategorised  ->  Sacred Singing Circle
  (2668, 2344), -- Uncategorised  ->  Slowed & Reverb
  (2668, 2376), -- Uncategorised  ->  Sound Effects
  (2668, 2574), -- Uncategorised  ->  Toypop
  (2668, 2765), -- Uncategorised  ->  Worldbeat
  (2681, 240), -- Uyghur Music  ->  Bayawan
  (2681, 2645), -- Uyghur Music  ->  Twelve Muqam
  (2693, 217), -- Vapor  ->  Barber Beats
  (2693, 767), -- Vapor  ->  Dreampunk
  (2693, 1003), -- Vapor  ->  Future Funk
  (2693, 1155), -- Vapor  ->  Hardvapour
  (2693, 2680), -- Vapor  ->  Utopian Virtual
  (2693, 2694), -- Vapor  ->  Vapornoise
  (2693, 2695), -- Vapor  ->  Vaportrap
  (2693, 2696), -- Vapor  ->  Vaporwave
  (2696, 366), -- Vaporwave  ->  Broken Transmission
  (2696, 812), -- Vaporwave  ->  Eccojams
  (2696, 1533), -- Vaporwave  ->  Mallsoft
  (2696, 2346), -- Vaporwave  ->  Slushwave
  (2697, 2698), -- Vaudeville  ->  Vaudeville Blues
  (2700, 1116), -- Vegan Straight Edge  ->  H8000
  (2700, 1150), -- Vegan Straight Edge  ->  Hardline
  (2703, 2707), -- Vietnamese Court Music  ->  Vietnamese Opera
  (2704, 539), -- Vietnamese Folk Music  ->  Chèo
  (2704, 2085), -- Vietnamese Folk Music  ->  Quan họ
  (2704, 2774), -- Vietnamese Folk Music  ->  Xẩm
  (2705, 309), -- Vietnamese Music  ->  Bolero Việt Nam
  (2705, 399), -- Vietnamese Music  ->  Ca trù
  (2705, 656), -- Vietnamese Music  ->  Cải lương
  (2705, 1223), -- Vietnamese Music  ->  Hát lô tô
  (2705, 1795), -- Vietnamese Music  ->  Ngâm thơ
  (2705, 1796), -- Vietnamese Music  ->  Nhạc tiền chiến
  (2705, 1797), -- Vietnamese Music  ->  Nhạc vàng
  (2705, 1798), -- Vietnamese Music  ->  Nhạc đỏ
  (2705, 2649), -- Vietnamese Music  ->  Tân cổ giao duyên
  (2705, 2703), -- Vietnamese Music  ->  Vietnamese Court Music
  (2705, 2704), -- Vietnamese Music  ->  Vietnamese Folk Music
  (2715, 1418), -- Visual kei  ->  Kote kei
  (2715, 1715), -- Visual kei  ->  Nagoya kei
  (2715, 2352), -- Visual kei  ->  Soft Visual
  (2717, 218), -- Vocal Group  ->  Barbershop
  (2717, 756), -- Vocal Group  ->  Doo-Wop
  (2718, 2721), -- Vocal Jazz  ->  Vocalese
  (2722, 2679), -- Vocaloid Scene  ->  Utaite
  (2724, 224), -- Volga-Ural Folk Music  ->  Bashkir Folk Music
  (2724, 538), -- Volga-Ural Folk Music  ->  Chuvash Folk Music
  (2724, 1411), -- Volga-Ural Folk Music  ->  Komi Folk Music
  (2724, 1560), -- Volga-Ural Folk Music  ->  Mari Folk Music
  (2724, 1664), -- Volga-Ural Folk Music  ->  Mordvin Folk Music
  (2724, 2652), -- Volga-Ural Folk Music  ->  Udmurt Folk Music
  (2724, 2723), -- Volga-Ural Folk Music  ->  Volga Tatar Folk Music
  (2728, 1288), -- Wa Euro  ->  J-Euro
  (2732, 2689), -- Waltz  ->  Vals venezolano
  (2732, 2690), -- Waltz  ->  Valsa brasileira
  (2738, 1156), -- Wave  ->  Hardwave
  (2738, 1735), -- Wave  ->  Neo-Grime
  (2742, 39), -- West African Music  ->  Afro-Funk
  (2742, 41), -- West African Music  ->  Afro-Rock
  (2742, 42), -- West African Music  ->  Afrobeat
  (2742, 54), -- West African Music  ->  Akan Music
  (2742, 188), -- West African Music  ->  Balani Show
  (2742, 661), -- West African Music  ->  Dagomba Music
  (2742, 871), -- West African Music  ->  Ewe Music
  (2742, 931), -- West African Music  ->  Fon Music
  (2742, 974), -- West African Music  ->  Fula Music
  (2742, 1093), -- West African Music  ->  Griot Music
  (2742, 1110), -- West African Music  ->  Gumbe
  (2742, 1162), -- West African Music  ->  Hausa Music
  (2742, 1177), -- West African Music  ->  Highlife
  (2742, 1186), -- West African Music  ->  Hipco
  (2742, 1187), -- West African Music  ->  Hiplife
  (2742, 1230), -- West African Music  ->  Igbo Music
  (2742, 1356), -- West African Music  ->  Kabye Folk Music
  (2742, 1424), -- West African Music  ->  Kru Music
  (2742, 1541), -- West African Music  ->  Mande Music
  (2742, 1670), -- West African Music  ->  Mossi Music
  (2742, 2365), -- West African Music  ->  Songhai Music
  (2742, 2578), -- West African Music  ->  Tradi-moderne ivoirien
  (2742, 2737), -- West African Music  ->  Wassoulou
  (2742, 2759), -- West African Music  ->  Wolof Music
  (2742, 2786), -- West African Music  ->  Yoruba Music
  (2742, 2815), -- West African Music  ->  Zouglou
  (2743, 61), -- West Asian Folk Music  ->  Alevi Folk Music
  (2743, 125), -- West Asian Folk Music  ->  Armenian Folk Music
  (2743, 148), -- West Asian Folk Music  ->  Assyrian Folk Music
  (2743, 170), -- West Asian Folk Music  ->  Ayyalah
  (2743, 900), -- West Asian Folk Music  ->  Fijiri
  (2743, 1277), -- West Asian Folk Music  ->  Israeli Folk Music
  (2743, 1506), -- West Asian Folk Music  ->  Luri Folk Music
  (2743, 1612), -- West Asian Folk Music  ->  Meyxana
  (2743, 1939), -- West Asian Folk Music  ->  Persian Folk Music
  (2743, 2634), -- West Asian Folk Music  ->  Turkish Folk Music
  (2744, 126), -- West Asian Music  ->  Armenian Music
  (2744, 172), -- West Asian Music  ->  Azerbaijani Music
  (2744, 455), -- West Asian Music  ->  Caucasian Music
  (2744, 659), -- West Asian Music  ->  Dabke
  (2744, 1055), -- West Asian Music  ->  Gilaki Music
  (2744, 1272), -- West Asian Music  ->  Iraqi Maqam
  (2744, 1393), -- West Asian Music  ->  Khaliji Music
  (2744, 1436), -- West Asian Music  ->  Kurdish Music
  (2744, 1473), -- West Asian Music  ->  Levantine Arabic Music
  (2744, 1515), -- West Asian Music  ->  Maftirim
  (2744, 1607), -- West Asian Music  ->  Mesopotamian Music
  (2744, 1696), -- West Asian Music  ->  Muzika mizrahit
  (2744, 1940), -- West Asian Music  ->  Persian Music
  (2744, 2636), -- West Asian Music  ->  Turkish Music
  (2744, 2743), -- West Asian Music  ->  West Asian Folk Music
  (2744, 2782), -- West Asian Music  ->  Yemenite Jewish Diwan
  (2746, 238), -- West Coast Hip Hop  ->  Bay Area Hip Hop
  (2751, 138), -- Western Classical Music  ->  Art Song
  (2751, 179), -- Western Classical Music  ->  Bagatelle
  (2751, 198), -- Western Classical Music  ->  Ballet
  (2751, 221), -- Western Classical Music  ->  Baroque Music
  (2751, 223), -- Western Classical Music  ->  Baroque Suite
  (2751, 331), -- Western Classical Music  ->  Brazilian Classical Music
  (2751, 395), -- Western Classical Music  ->  Byzantine Music
  (2751, 418), -- Western Classical Music  ->  Cantata
  (2751, 431), -- Western Classical Music  ->  Canzona
  (2751, 441), -- Western Classical Music  ->  Capriccio
  (2751, 477), -- Western Classical Music  ->  Chamber Music
  (2751, 491), -- Western Classical Music  ->  Character Piece
  (2751, 524), -- Western Classical Music  ->  Choral
  (2751, 542), -- Western Classical Music  ->  Cinematic Classical
  (2751, 547), -- Western Classical Music  ->  Classic Ragtime
  (2751, 551), -- Western Classical Music  ->  Classical Period
  (2751, 574), -- Western Classical Music  ->  Concerto
  (2751, 743), -- Western Classical Music  ->  Divertissement
  (2751, 845), -- Western Classical Music  ->  English Pastoral School
  (2751, 887), -- Western Classical Music  ->  Fantasia
  (2751, 972), -- Western Classical Music  ->  Fugue
  (2751, 1455), -- Western Classical Music  ->  Latin American Classical Music
  (2751, 1478), -- Western Classical Music  ->  Light Music
  (2751, 1513), -- Western Classical Music  ->  Madrigal
  (2751, 1584), -- Western Classical Music  ->  Medieval Classical Music
  (2751, 1647), -- Western Classical Music  ->  Modern Classical
  (2751, 1671), -- Western Classical Music  ->  Motet
  (2751, 1745), -- Western Classical Music  ->  Neoclassicism
  (2751, 1880), -- Western Classical Music  ->  Opera
  (2751, 1888), -- Western Classical Music  ->  Oratorio
  (2751, 1889), -- Western Classical Music  ->  Orchestral Music
  (2751, 1904), -- Western Classical Music  ->  Overture
  (2751, 1932), -- Western Classical Music  ->  Passion
  (2751, 2036), -- Western Classical Music  ->  Prelude
  (2751, 2131), -- Western Classical Music  ->  Renaissance Music
  (2751, 2140), -- Western Classical Music  ->  Ricercar
  (2751, 2172), -- Western Classical Music  ->  Roman School
  (2751, 2180), -- Western Classical Music  ->  Romanticism
  (2751, 2272), -- Western Classical Music  ->  Serenade
  (2751, 2364), -- Western Classical Music  ->  Sonata
  (2751, 2406), -- Western Classical Music  ->  Spanish Classical Music
  (2751, 2467), -- Western Classical Music  ->  Symphony
  (2751, 2544), -- Western Classical Music  ->  Theme and Variation
  (2751, 2561), -- Western Classical Music  ->  Toccata
  (2751, 2819), -- Western Classical Music  ->  Étude
  (2759, 1577), -- Wolof Music  ->  Mbalax
  (2759, 2504), -- Wolof Music  ->  Tassu
  (2762, 113), -- Wonky  ->  Aquacrunk
  (2764, 10), -- Work Song  ->  Aboio
  (2764, 894), -- Work Song  ->  Field Hollers
  (2764, 1128), -- Work Song  ->  Haozi
  (2764, 1625), -- Work Song  ->  Military Cadence
  (2764, 2258), -- Work Song  ->  Sea Shanty
  (2764, 2288), -- Work Song  ->  Shan'ge
  (2764, 2821), -- Work Song  ->  Òrain luaidh
  (2784, 607), -- Yodeling  ->  Country Yodeling
  (2784, 1724), -- Yodeling  ->  Naturjodel
  (2786, 111), -- Yoruba Music  ->  Apala
  (2786, 973), -- Yoruba Music  ->  Fuji
  (2786, 1352), -- Yoruba Music  ->  Jùjú
  (2786, 2235), -- Yoruba Music  ->  Santería Music
  (2786, 2730), -- Yoruba Music  ->  Waka
  (2786, 2785), -- Yoruba Music  ->  Yoruba Folk Opera
  (2788, 1899), -- YTPMV  ->  otoMAD
  (2797, 1114), -- Zarzuela  ->  Género chico
  (2797, 2798), -- Zarzuela  ->  Zarzuela barroca
  (2797, 2799), -- Zarzuela  ->  Zarzuela grande
  (2815, 609), -- Zouglou  ->  Coupé-décalé
  (2816, 401), -- Zouk  ->  Cabo-Zouk
  (2816, 2817), -- Zouk  ->  Zouk Love
  (2818, 1831), -- Zydeco  ->  Nouveau zydeco
  (2820, 2265), -- Òrain Ghàidhlig  ->  Seinn nan salm
  (2820, 2821)  -- Òrain Ghàidhlig  ->  Òrain luaidh;


-- =============================================================================
-- 3. DESCRIPTOR NODES (descriptors)
-- =============================================================================
-- Complete live descriptor node list with the same three derived counters.
INSERT INTO public.descriptors (descriptor_id, descriptor_name, ref_count, children_count, total_ref_count) VALUES
  (1, 'A cappella', 0, 0, 0), -- LEAF
  (2, 'About music', 0, 0, 0), -- LEAF
  (3, 'Abstract', 0, 0, 0), -- LEAF
  (4, 'Acoustic', 1, 0, 1), -- LEAF
  (5, 'Addiction', 0, 0, 0), -- LEAF
  (6, 'Adolescence', 0, 0, 0), -- LEAF
  (7, 'Afterlife', 0, 1, 0), -- 1 children
  (8, 'Ageing', 0, 0, 0), -- LEAF
  (9, 'aggressive', 16, 0, 16), -- LEAF
  (10, 'Aggressive', 0, 0, 0), -- LEAF
  (11, 'Alcohol', 0, 0, 0), -- LEAF
  (12, 'Aleatory', 0, 0, 0), -- LEAF
  (13, 'aleatory', 2, 0, 2), -- LEAF
  (14, 'Alienation', 0, 0, 0), -- LEAF
  (15, 'Aliens', 0, 0, 0), -- LEAF
  (16, 'Alter ego', 0, 0, 0), -- LEAF
  (17, 'Altruistic', 0, 0, 0), -- LEAF
  (18, 'Anarchism', 0, 0, 0), -- LEAF
  (19, 'Androgynous vocals', 1, 0, 1), -- LEAF
  (20, 'androgynous vocals', 1, 0, 1), -- LEAF
  (21, 'Angry', 0, 0, 0), -- LEAF
  (22, 'Angular', 0, 0, 0), -- LEAF
  (23, 'Animals', 0, 5, 0), -- 5 children
  (24, 'Anime and manga', 0, 0, 0), -- LEAF
  (25, 'Anthemic', 0, 0, 0), -- LEAF
  (26, 'Anti-authoritarian', 0, 0, 0), -- LEAF
  (27, 'Anticonsumerism', 0, 0, 0), -- LEAF
  (28, 'Antidiscrimination', 0, 1, 0), -- 1 children
  (29, 'Antidrug', 0, 0, 0), -- LEAF
  (30, 'Antiracism', 0, 0, 0), -- LEAF
  (31, 'Antireligious', 0, 0, 0), -- LEAF
  (32, 'anxious', 2, 0, 2), -- LEAF
  (33, 'Anxious', 0, 0, 0), -- LEAF
  (34, 'Apathetic', 0, 0, 0), -- LEAF
  (35, 'Apocalyptic', 0, 0, 0), -- LEAF
  (36, 'apocalyptic', 13, 0, 13), -- LEAF
  (37, 'Apology', 0, 0, 0), -- LEAF
  (38, 'Aquatic', 1, 0, 1), -- LEAF
  (39, 'Association football', 0, 0, 0), -- LEAF
  (40, 'Atmosphere', 0, 51, 6), -- 51 children
  (41, 'atmospheric', 18, 0, 18), -- LEAF
  (42, 'Atmospheric', 1, 0, 1), -- LEAF
  (43, 'atonal', 2, 0, 2), -- LEAF
  (44, 'Atonal', 0, 0, 0), -- LEAF
  (45, 'Autumn', 1, 0, 1), -- LEAF
  (46, 'Avant-garde', 0, 0, 0), -- LEAF
  (47, 'avant-garde', 4, 0, 4), -- LEAF
  (48, 'Bahá''í', 0, 0, 0), -- LEAF
  (49, 'Ballad', 0, 0, 0), -- LEAF
  (50, 'Baseball', 0, 0, 0), -- LEAF
  (51, 'Basketball', 0, 0, 0), -- LEAF
  (52, 'Bassy', 0, 0, 0), -- LEAF
  (53, 'bassy', 1, 0, 1), -- LEAF
  (54, 'Beach', 0, 0, 0), -- LEAF
  (55, 'Beauty', 0, 0, 0), -- LEAF
  (56, 'Belting', 0, 0, 0), -- LEAF
  (57, 'Betrayal', 0, 1, 0), -- 1 children
  (58, 'Biblical', 0, 0, 0), -- LEAF
  (59, 'Birds', 0, 0, 0), -- LEAF
  (60, 'Birthday', 0, 0, 0), -- LEAF
  (61, 'Bisexual', 0, 0, 0), -- LEAF
  (62, 'bittersweet', 1, 0, 1), -- LEAF
  (63, 'Bittersweet', 0, 0, 0), -- LEAF
  (64, 'Blast beats', 0, 0, 0), -- LEAF
  (65, 'Boastful', 0, 0, 0), -- LEAF
  (66, 'Boredom', 0, 0, 0), -- LEAF
  (67, 'Bouncy', 0, 0, 0), -- LEAF
  (68, 'Boxing', 0, 0, 0), -- LEAF
  (69, 'Breakup', 1, 0, 1), -- LEAF
  (70, 'bright', 1, 0, 1), -- LEAF
  (71, 'Bright', 0, 0, 0), -- LEAF
  (72, 'Buddhist', 0, 0, 0), -- LEAF
  (73, 'Buzzy', 0, 0, 0), -- LEAF
  (74, 'Call and response', 0, 0, 0), -- LEAF
  (75, 'Callback', 0, 0, 0), -- LEAF
  (76, 'Calm', 0, 1, 0), -- 1 children
  (77, 'Cannabis', 0, 0, 0), -- LEAF
  (78, 'Carnaval', 0, 0, 0), -- LEAF
  (79, 'Cars', 0, 0, 0), -- LEAF
  (80, 'Cats', 0, 0, 0), -- LEAF
  (81, 'Cautionary', 0, 0, 0), -- LEAF
  (82, 'Cavernous', 0, 0, 0), -- LEAF
  (83, 'chaotic', 19, 0, 19), -- LEAF
  (84, 'Chaotic', 1, 0, 1), -- LEAF
  (85, 'Childhood', 0, 0, 0), -- LEAF
  (86, 'Choral', 0, 0, 0), -- LEAF
  (87, 'Christian', 0, 0, 0), -- LEAF
  (88, 'Christmas', 0, 0, 0), -- LEAF
  (89, 'Chugging', 0, 0, 0), -- LEAF
  (90, 'Cocaine', 0, 0, 0), -- LEAF
  (91, 'Code-mixing', 0, 0, 0), -- LEAF
  (92, 'cold', 10, 0, 10), -- LEAF
  (93, 'Cold', 0, 0, 0), -- LEAF
  (94, 'Comics', 1, 0, 1), -- LEAF
  (95, 'Community', 0, 0, 0), -- LEAF
  (96, 'Compassionate', 0, 0, 0), -- LEAF
  (97, 'Complex', 0, 0, 0), -- LEAF
  (98, 'complex', 2, 0, 2), -- LEAF
  (99, 'Composition', 0, 12, 1), -- 12 children
  (100, 'concept album', 1, 0, 1), -- LEAF
  (101, 'Concept album', 1, 0, 1), -- LEAF
  (102, 'Conscious', 0, 2, 0), -- 2 children
  (103, 'Conservatism', 0, 0, 0), -- LEAF
  (104, 'Conspiracy', 0, 0, 0), -- LEAF
  (105, 'Cosmetics', 0, 0, 0), -- LEAF
  (106, 'Cosmic horror', 0, 0, 0), -- LEAF
  (107, 'Courage', 0, 0, 0), -- LEAF
  (108, 'cozy', 1, 0, 1), -- LEAF
  (109, 'Cozy', 0, 0, 0), -- LEAF
  (110, 'Crackly', 0, 0, 0), -- LEAF
  (111, 'crackly', 2, 0, 2), -- LEAF
  (112, 'Crime', 0, 1, 0), -- 1 children
  (113, 'Crooning', 0, 0, 0), -- LEAF
  (114, 'Cryptic', 0, 0, 0), -- LEAF
  (115, 'cryptic', 2, 0, 2), -- LEAF
  (116, 'Cyberpunk', 0, 0, 0), -- LEAF
  (117, 'Cynical', 0, 0, 0), -- LEAF
  (118, 'Dancing', 0, 0, 0), -- LEAF
  (119, 'dark', 11, 0, 11), -- LEAF
  (120, 'Dark', 0, 3, 0), -- 3 children
  (121, 'Dark humor', 0, 0, 0), -- LEAF
  (122, 'Daytime', 0, 0, 0), -- LEAF
  (123, 'Deadpan', 0, 0, 0), -- LEAF
  (124, 'death', 7, 0, 7), -- LEAF
  (125, 'Death', 0, 2, 0), -- 2 children
  (126, 'Decay', 0, 0, 0), -- LEAF
  (127, 'dense', 9, 0, 9), -- LEAF
  (128, 'Dense', 1, 0, 1), -- LEAF
  (129, 'Depressing', 2, 0, 2), -- LEAF
  (130, 'depressive', 3, 0, 3), -- LEAF
  (131, 'Depressive', 1, 0, 1), -- LEAF
  (132, 'Desert', 0, 0, 0), -- LEAF
  (133, 'Desolate', 0, 0, 0), -- LEAF
  (134, 'Dialogue', 0, 0, 0), -- LEAF
  (135, 'Disaster', 0, 1, 0), -- 1 children
  (136, 'Disease', 0, 0, 0), -- LEAF
  (137, 'Dishonesty', 0, 0, 0), -- LEAF
  (138, 'Diss', 0, 0, 0), -- LEAF
  (139, 'Dissonant', 1, 0, 1), -- LEAF
  (140, 'dissonant', 3, 0, 3), -- LEAF
  (141, 'Disturbing', 0, 0, 0), -- LEAF
  (142, 'disturbing', 16, 0, 16), -- LEAF
  (143, 'Divorce', 0, 0, 0), -- LEAF
  (144, 'Domestic', 0, 0, 0), -- LEAF
  (145, 'Dreams', 0, 0, 0), -- LEAF
  (146, 'Drought', 0, 0, 0), -- LEAF
  (147, 'Drugs', 0, 7, 0), -- 7 children
  (148, 'drums', 1, 0, 1), -- LEAF
  (149, 'Duet', 0, 0, 0), -- LEAF
  (150, 'Dystopian', 0, 1, 0), -- 1 children
  (151, 'eclectic', 1, 0, 1), -- LEAF
  (152, 'Eclectic', 1, 0, 1), -- LEAF
  (153, 'Educational', 0, 0, 0), -- LEAF
  (154, 'energetic', 2, 0, 2), -- LEAF
  (155, 'Energetic', 1, 1, 2), -- 1 children
  (156, 'Ensemble', 0, 8, 1), -- 8 children
  (157, 'Entertainment industry', 0, 0, 0), -- LEAF
  (158, 'Envy', 0, 0, 0), -- LEAF
  (159, 'Epic', 0, 0, 0), -- LEAF
  (160, 'Escapism', 0, 0, 0), -- LEAF
  (161, 'Ethereal', 1, 0, 1), -- LEAF
  (162, 'ethereal', 3, 0, 3), -- LEAF
  (163, 'Evening', 0, 0, 0), -- LEAF
  (164, 'Everyday life', 0, 0, 0), -- LEAF
  (165, 'Evironmentalism', 0, 0, 0), -- LEAF
  (166, 'Existential', 0, 0, 0), -- LEAF
  (167, 'Failure', 0, 0, 0), -- LEAF
  (168, 'Fairy tale', 0, 0, 0), -- LEAF
  (169, 'Falsetto', 0, 0, 0), -- LEAF
  (170, 'Fame', 0, 0, 0), -- LEAF
  (171, 'Family', 0, 1, 0), -- 1 children
  (172, 'Fans', 0, 0, 0), -- LEAF
  (173, 'Fantasy', 0, 0, 0), -- LEAF
  (174, 'Farewell', 0, 0, 0), -- LEAF
  (175, 'Farming', 0, 0, 0), -- LEAF
  (176, 'Fashion', 0, 1, 0), -- 1 children
  (177, 'Female Frontman/Vocalist', 1, 0, 1), -- LEAF
  (178, 'Female Frontman/vocalist', 1, 0, 1), -- LEAF
  (179, 'female vocalist', 1, 0, 1), -- LEAF
  (180, 'Female vocalist', 0, 0, 0), -- LEAF
  (181, 'female/male vocalist', 1, 0, 1), -- LEAF
  (182, 'Feminism', 0, 0, 0), -- LEAF
  (183, 'Film', 0, 0, 0), -- LEAF
  (184, 'Fire', 0, 0, 0), -- LEAF
  (185, 'Fishing', 0, 0, 0), -- LEAF
  (186, 'Fitness', 0, 0, 0), -- LEAF
  (187, 'Flirting', 0, 0, 0), -- LEAF
  (188, 'Flowers', 0, 0, 0), -- LEAF
  (189, 'Folklore', 0, 0, 0), -- LEAF
  (190, 'Food', 0, 0, 0), -- LEAF
  (191, 'Forest', 1, 0, 1), -- LEAF
  (192, 'Form', 0, 26, 2), -- 26 children
  (193, 'Four on the floor', 0, 0, 0), -- LEAF
  (194, 'Free rhythm', 0, 0, 0), -- LEAF
  (195, 'Freestyle', 0, 0, 0), -- LEAF
  (196, 'Friendship', 0, 0, 0), -- LEAF
  (197, 'funereal', 2, 0, 2), -- LEAF
  (198, 'Funereal', 0, 0, 0), -- LEAF
  (199, 'futuristic', 2, 0, 2), -- LEAF
  (200, 'Futuristic', 0, 0, 0), -- LEAF
  (201, 'Fuzzy', 0, 0, 0), -- LEAF
  (202, 'Gallop', 0, 0, 0), -- LEAF
  (203, 'Gambling', 0, 0, 0), -- LEAF
  (204, 'Gang vocals', 0, 0, 0), -- LEAF
  (205, 'Gay', 0, 0, 0), -- LEAF
  (206, 'Gender', 0, 6, 0), -- 6 children
  (207, 'Gender dysphoria', 0, 0, 0), -- LEAF
  (208, 'Generative music', 0, 0, 0), -- LEAF
  (209, 'Ghosts', 0, 0, 0), -- LEAF
  (210, 'Gore', 0, 0, 0), -- LEAF
  (211, 'Grassland', 0, 0, 0), -- LEAF
  (212, 'Gratitude', 0, 0, 0), -- LEAF
  (213, 'Greed', 0, 0, 0), -- LEAF
  (214, 'Grief', 0, 0, 0), -- LEAF
  (215, 'Growling', 0, 0, 0), -- LEAF
  (216, 'Guns', 0, 0, 0), -- LEAF
  (217, 'Halloween', 0, 0, 0), -- LEAF
  (218, 'hallucinogens', 1, 0, 1), -- LEAF
  (219, 'Hallucinogens', 0, 0, 0), -- LEAF
  (220, 'Happy', 0, 0, 0), -- LEAF
  (221, 'Harsh vocals', 0, 3, 0), -- 3 children
  (222, 'Hateful', 0, 0, 0), -- LEAF
  (223, 'hateful', 1, 0, 1), -- LEAF
  (224, 'Hazy', 0, 0, 0), -- LEAF
  (225, 'Healing', 0, 0, 0), -- LEAF
  (226, 'Health', 0, 8, 0), -- 8 children
  (227, 'heavy', 5, 0, 5), -- LEAF
  (228, 'Heavy', 0, 0, 0), -- LEAF
  (229, 'Hedonism', 0, 0, 0), -- LEAF
  (230, 'Hindu', 0, 0, 0), -- LEAF
  (231, 'history', 1, 0, 1), -- LEAF
  (232, 'Holiday', 0, 3, 0), -- 3 children
  (233, 'Homesickness', 0, 0, 0), -- LEAF
  (234, 'Homicide', 0, 0, 0), -- LEAF
  (235, 'Horror', 0, 1, 0), -- 1 children
  (236, 'Horses', 0, 0, 0), -- LEAF
  (237, 'Humming', 0, 0, 0), -- LEAF
  (238, 'Humorous', 1, 1, 1), -- 1 children
  (239, 'humorous', 2, 0, 2), -- LEAF
  (240, 'Hunting', 0, 0, 0), -- LEAF
  (241, 'Hypnotic', 0, 0, 0), -- LEAF
  (242, 'hypnotic', 7, 0, 7), -- LEAF
  (243, 'Ideology', 0, 27, 0), -- 27 children
  (244, 'improvisation', 1, 0, 1), -- LEAF
  (245, 'Improvisiation', 0, 2, 0), -- 2 children
  (246, 'Indigeneity', 0, 0, 0), -- LEAF
  (247, 'Individuality', 0, 0, 0), -- LEAF
  (248, 'Infernal', 0, 0, 0), -- LEAF
  (249, 'infernal', 11, 0, 11), -- LEAF
  (250, 'Infidelity', 0, 0, 0), -- LEAF
  (251, 'Injury', 0, 0, 0), -- LEAF
  (252, 'Insecure', 0, 0, 0), -- LEAF
  (253, 'Instrumental', 0, 0, 0), -- LEAF
  (254, 'Interlude', 0, 0, 0), -- LEAF
  (255, 'Internet', 0, 0, 0), -- LEAF
  (256, 'Interpolation', 0, 0, 0), -- LEAF
  (257, 'Intro', 0, 0, 0), -- LEAF
  (258, 'Introspective', 1, 1, 1), -- 1 children
  (259, 'Islamic', 0, 0, 0), -- LEAF
  (260, 'Jain', 0, 0, 0), -- LEAF
  (261, 'Jamming', 0, 0, 0), -- LEAF
  (262, 'Judiac', 0, 0, 0), -- LEAF
  (263, 'Law', 0, 0, 0), -- LEAF
  (264, 'Leisure', 0, 0, 0), -- LEAF
  (265, 'Leitmotif', 0, 0, 0), -- LEAF
  (266, 'Lesbian', 0, 0, 0), -- LEAF
  (267, 'lethargic', 1, 0, 1), -- LEAF
  (268, 'Lethargic', 0, 0, 0), -- LEAF
  (269, 'LGBTQ', 0, 5, 0), -- 5 children
  (270, 'List song', 0, 0, 0), -- LEAF
  (271, 'Literature', 0, 2, 1), -- 2 children
  (272, 'Lo-fi', 0, 0, 0), -- LEAF
  (273, 'lo-fi', 1, 0, 1), -- LEAF
  (274, 'Lobit', 0, 0, 0), -- LEAF
  (275, 'lonely', 3, 0, 3), -- LEAF
  (276, 'Lonely', 0, 0, 0), -- LEAF
  (277, 'Long-distance relationship', 0, 0, 0), -- LEAF
  (278, 'longing', 2, 0, 2), -- LEAF
  (279, 'Longing', 0, 0, 0), -- LEAF
  (280, 'Love', 0, 4, 1), -- 4 children
  (281, 'Loyalty', 0, 0, 0), -- LEAF
  (282, 'Lush', 2, 0, 2), -- LEAF
  (283, 'lush', 1, 0, 1), -- LEAF
  (284, 'Lyrical dissonance', 0, 0, 0), -- LEAF
  (285, 'Lyrics', 0, 31, 1), -- 31 children
  (286, 'Macabre', 0, 1, 0), -- 1 children
  (287, 'male vocalist', 7, 0, 7), -- LEAF
  (288, 'Male vocalist', 0, 0, 0), -- LEAF
  (289, 'Manhood', 0, 0, 0), -- LEAF
  (290, 'Manic', 1, 0, 1), -- LEAF
  (291, 'manic', 9, 0, 9), -- LEAF
  (292, 'Maritime', 0, 0, 0), -- LEAF
  (293, 'Marriage', 0, 1, 0), -- 1 children
  (294, 'Martial', 0, 0, 0), -- LEAF
  (295, 'Mathematics', 0, 0, 0), -- LEAF
  (296, 'Maximalist', 0, 0, 0), -- LEAF
  (297, 'mechanical', 12, 0, 12), -- LEAF
  (298, 'Medieval', 0, 0, 0), -- LEAF
  (299, 'Meditative', 0, 0, 0), -- LEAF
  (300, 'meditative', 1, 0, 1), -- LEAF
  (301, 'Medley', 0, 0, 0), -- LEAF
  (302, 'melancholic', 7, 0, 7), -- LEAF
  (303, 'Melancholic', 0, 0, 0), -- LEAF
  (304, 'mellow', 1, 0, 1), -- LEAF
  (305, 'Mellow', 1, 1, 1), -- 1 children
  (306, 'Melodic', 1, 0, 1), -- LEAF
  (307, 'Memory', 0, 0, 0), -- LEAF
  (308, 'Menacing', 0, 0, 0), -- LEAF
  (309, 'Mental health', 0, 3, 0), -- 3 children
  (310, 'Microtonal', 0, 0, 0), -- LEAF
  (311, 'Migration', 0, 0, 0), -- LEAF
  (312, 'Minimalistic', 0, 0, 0), -- LEAF
  (313, 'Mining', 0, 0, 0), -- LEAF
  (314, 'Misanthropic', 0, 0, 0), -- LEAF
  (315, 'misanthropic', 1, 0, 1), -- LEAF
  (316, 'Money', 0, 2, 0), -- 2 children
  (317, 'Monologue', 0, 0, 0), -- LEAF
  (318, 'Monophonic', 0, 0, 0), -- LEAF
  (319, 'Monsters', 0, 1, 0), -- 1 children
  (320, 'Mood', 0, 28, 7), -- 28 children
  (321, 'Morning', 0, 0, 0), -- LEAF
  (322, 'Mountains', 0, 0, 0), -- LEAF
  (323, 'Movement', 0, 0, 0), -- LEAF
  (324, 'Muffled', 0, 0, 0), -- LEAF
  (325, 'mysterious', 2, 0, 2), -- LEAF
  (326, 'Mysterious', 0, 0, 0), -- LEAF
  (327, 'Mythology', 0, 0, 0), -- LEAF
  (328, 'Narrative', 0, 0, 0), -- LEAF
  (329, 'Nationalism', 0, 0, 0), -- LEAF
  (330, 'Natural', 0, 9, 2), -- 9 children
  (331, 'Nature', 1, 9, 1), -- 9 children
  (332, 'Nicotine', 0, 0, 0), -- LEAF
  (333, 'Nightlife', 0, 0, 0), -- LEAF
  (334, 'Nihilistic', 0, 0, 0), -- LEAF
  (335, 'Nocturnal', 1, 0, 1), -- LEAF
  (336, 'nocturnal', 9, 0, 9), -- LEAF
  (337, 'Noisy', 0, 0, 0), -- LEAF
  (338, 'noisy', 6, 0, 6), -- LEAF
  (339, 'Nonbinary', 0, 0, 0), -- LEAF
  (340, 'Nonbinary vocalist', 0, 0, 0), -- LEAF
  (341, 'Nonlexical vocables', 0, 2, 0), -- 2 children
  (342, 'Nostalgia', 0, 0, 0), -- LEAF
  (343, 'Novelty', 0, 0, 0), -- LEAF
  (344, 'Obsession', 0, 0, 0), -- LEAF
  (345, 'Occult', 0, 0, 0), -- LEAF
  (346, 'occult', 3, 0, 3), -- LEAF
  (347, 'Older adulthood', 0, 0, 0), -- LEAF
  (348, 'Ominous', 0, 0, 0), -- LEAF
  (349, 'ominous', 12, 0, 12), -- LEAF
  (350, 'Opioids', 0, 0, 0), -- LEAF
  (351, 'Optimistic', 0, 0, 0), -- LEAF
  (352, 'Orchestral', 0, 0, 0), -- LEAF
  (353, 'Outro', 0, 0, 0), -- LEAF
  (354, 'Pacifism', 0, 0, 0), -- LEAF
  (355, 'Pagan', 0, 0, 0), -- LEAF
  (356, 'Paranoia', 0, 0, 0), -- LEAF
  (357, 'Paranormal', 0, 1, 0), -- 1 children
  (358, 'Parenthood', 0, 0, 0), -- LEAF
  (359, 'Parody', 0, 0, 0), -- LEAF
  (360, 'Party', 0, 0, 0), -- LEAF
  (361, 'Passionate', 1, 0, 1), -- LEAF
  (362, 'Pastiche', 0, 0, 0), -- LEAF
  (363, 'Pastoral', 0, 0, 0), -- LEAF
  (364, 'Patriotic', 0, 0, 0), -- LEAF
  (365, 'peaceful', 1, 0, 1), -- LEAF
  (366, 'Peaceful', 0, 0, 0), -- LEAF
  (367, 'Pessimistic', 0, 0, 0), -- LEAF
  (368, 'Pets', 0, 0, 0), -- LEAF
  (369, 'Philosophical', 0, 2, 0), -- 2 children
  (370, 'philosophical', 1, 0, 1), -- LEAF
  (371, 'Phones', 0, 0, 0), -- LEAF
  (372, 'piercing', 3, 0, 3), -- LEAF
  (373, 'Piercing', 0, 0, 0), -- LEAF
  (374, 'Pig squealing', 0, 0, 0), -- LEAF
  (375, 'Pirates', 0, 0, 0), -- LEAF
  (376, 'Pitched-down vocals', 0, 0, 0), -- LEAF
  (377, 'Pitched-up vocals', 0, 0, 0), -- LEAF
  (378, 'Plants', 0, 1, 0), -- 1 children
  (379, 'playful', 1, 0, 1), -- LEAF
  (380, 'Playful', 1, 0, 1), -- LEAF
  (381, 'Plodding', 0, 0, 0), -- LEAF
  (382, 'Poetic', 0, 0, 0), -- LEAF
  (383, 'Police', 0, 0, 0), -- LEAF
  (384, 'political', 1, 0, 1), -- LEAF
  (385, 'Political', 0, 9, 0), -- 9 children
  (386, 'Polyphonic', 0, 0, 0), -- LEAF
  (387, 'Polyrhythm', 0, 0, 0), -- LEAF
  (388, 'Posse cut', 0, 0, 0), -- LEAF
  (389, 'Poverty', 0, 0, 0), -- LEAF
  (390, 'Prison', 0, 0, 0), -- LEAF
  (391, 'Production', 0, 4, 0), -- 4 children
  (392, 'Progressive', 0, 0, 0), -- LEAF
  (393, 'Propaganda', 0, 0, 0), -- LEAF
  (394, 'Protest', 0, 0, 0), -- LEAF
  (395, 'Provocative', 0, 0, 0), -- LEAF
  (396, 'psychedelic', 7, 0, 7), -- LEAF
  (397, 'Punchy', 0, 0, 0), -- LEAF
  (398, 'Pyschedelic', 0, 0, 0), -- LEAF
  (399, 'Quirky', 1, 0, 1), -- LEAF
  (400, 'Racing', 0, 0, 0), -- LEAF
  (401, 'Radio', 0, 0, 0), -- LEAF
  (402, 'Rain', 0, 0, 0), -- LEAF
  (403, 'rain', 1, 0, 1), -- LEAF
  (404, 'Rastafari', 0, 0, 0), -- LEAF
  (405, 'Raw', 0, 0, 0), -- LEAF
  (406, 'raw', 13, 0, 13), -- LEAF
  (407, 'Rebellious', 0, 0, 0), -- LEAF
  (408, 'Regret', 0, 0, 0), -- LEAF
  (409, 'Rejection', 0, 0, 0), -- LEAF
  (410, 'Religious', 0, 9, 0), -- 9 children
  (411, 'repetitive', 8, 0, 8), -- LEAF
  (412, 'Repetitive', 0, 0, 0), -- LEAF
  (413, 'Reprise', 0, 0, 0), -- LEAF
  (414, 'Revolution', 0, 0, 0), -- LEAF
  (415, 'rhythmic', 3, 0, 3), -- LEAF
  (416, 'Rhythmic', 1, 5, 1), -- 5 children
  (417, 'Ritualistic', 0, 0, 0), -- LEAF
  (418, 'ritualistic', 2, 0, 2), -- LEAF
  (419, 'Robots', 0, 0, 0), -- LEAF
  (420, 'Romantic', 0, 0, 0), -- LEAF
  (421, 'Rubato', 0, 0, 0), -- LEAF
  (422, 'rythmic', 1, 0, 1), -- LEAF
  (423, 'Sad', 0, 4, 1), -- 4 children
  (424, 'Sampling', 0, 1, 0), -- 1 children
  (425, 'sampling', 4, 0, 4), -- LEAF
  (426, 'Sarcastic', 0, 0, 0), -- LEAF
  (427, 'Sassy', 0, 0, 0), -- LEAF
  (428, 'satanic', 2, 0, 2), -- LEAF
  (429, 'Satanism', 0, 0, 0), -- LEAF
  (430, 'satirical', 1, 0, 1), -- LEAF
  (431, 'Satirical', 0, 0, 0), -- LEAF
  (432, 'scary', 7, 0, 7), -- LEAF
  (433, 'Scary', 0, 0, 0), -- LEAF
  (434, 'Scat singing', 0, 0, 0), -- LEAF
  (435, 'School', 0, 0, 0), -- LEAF
  (436, 'Science', 0, 0, 0), -- LEAF
  (437, 'Science fiction', 0, 1, 0), -- 1 children
  (438, 'Seasonal', 0, 4, 1), -- 4 children
  (439, 'Secrets', 0, 0, 0), -- LEAF
  (440, 'Section', 0, 5, 0), -- 5 children
  (441, 'Self-hatred', 0, 0, 0), -- LEAF
  (442, 'Self-love', 0, 0, 0), -- LEAF
  (443, 'Sensual', 0, 0, 0), -- LEAF
  (444, 'Sentimental', 0, 0, 0), -- LEAF
  (445, 'Serious', 0, 0, 0), -- LEAF
  (446, 'sexual', 2, 0, 2), -- LEAF
  (447, 'Sexual', 1, 0, 1), -- LEAF
  (448, 'Shamanism', 0, 0, 0), -- LEAF
  (449, 'Shopping', 0, 0, 0), -- LEAF
  (450, 'Shrieking', 0, 0, 0), -- LEAF
  (451, 'Sikh', 0, 0, 0), -- LEAF
  (452, 'Silence', 0, 0, 0), -- LEAF
  (453, 'Sing-rapping', 0, 0, 0), -- LEAF
  (454, 'Skateboarding', 0, 0, 0), -- LEAF
  (455, 'Skit', 0, 0, 0), -- LEAF
  (456, 'Sleep', 0, 1, 0), -- 1 children
  (457, 'Smooth', 0, 0, 0), -- LEAF
  (458, 'Sobriety', 0, 0, 0), -- LEAF
  (459, 'Socialism', 0, 0, 0), -- LEAF
  (460, 'Soft', 0, 0, 0), -- LEAF
  (461, 'Sombre', 0, 0, 0), -- LEAF
  (462, 'sombre', 6, 0, 6), -- LEAF
  (463, 'soothing', 2, 0, 2), -- LEAF
  (464, 'Soothing', 0, 0, 0), -- LEAF
  (465, 'Sounds Inhumane', 1, 0, 1), -- LEAF
  (466, 'Space', 0, 0, 0), -- LEAF
  (467, 'sparse', 2, 0, 2), -- LEAF
  (468, 'Sparse', 0, 0, 0), -- LEAF
  (469, 'Spiritual', 0, 0, 0), -- LEAF
  (470, 'Sports', 0, 7, 0), -- 7 children
  (471, 'Spring', 0, 0, 0), -- LEAF
  (472, 'Squelchy', 0, 0, 0), -- LEAF
  (473, 'Stomping', 0, 0, 0), -- LEAF
  (474, 'Storm', 0, 0, 0), -- LEAF
  (475, 'Stream of consciousness', 0, 0, 0), -- LEAF
  (476, 'Style', 0, 44, 9), -- 44 children
  (477, 'Suburban', 0, 0, 0), -- LEAF
  (478, 'Success', 0, 0, 0), -- LEAF
  (479, 'Suicide', 0, 0, 0), -- LEAF
  (480, 'Suite', 0, 0, 0), -- LEAF
  (481, 'Summer', 0, 0, 0), -- LEAF
  (482, 'Surreal', 1, 0, 1), -- LEAF
  (483, 'surreal', 8, 0, 8), -- LEAF
  (484, 'Suspenseful', 0, 0, 0), -- LEAF
  (485, 'suspenseful', 3, 0, 3), -- LEAF
  (486, 'Talk-singing', 0, 0, 0), -- LEAF
  (487, 'Technical', 0, 0, 0), -- LEAF
  (488, 'technical', 1, 0, 1), -- LEAF
  (489, 'Technique', 0, 22, 1), -- 22 children
  (490, 'Technology', 0, 1, 0), -- 1 children
  (491, 'Television', 0, 0, 0), -- LEAF
  (492, 'Theatrical', 0, 0, 0), -- LEAF
  (493, 'Theft', 0, 0, 0), -- LEAF
  (494, 'Theme', 0, 221, 6), -- 221 children
  (495, 'Throat singing', 0, 0, 0), -- LEAF
  (496, 'Through-composed', 0, 0, 0), -- LEAF
  (497, 'Ticking', 0, 0, 0), -- LEAF
  (498, 'Time', 0, 0, 0), -- LEAF
  (499, 'Toasting', 0, 0, 0), -- LEAF
  (500, 'Tone', 0, 23, 1), -- 23 children
  (501, 'Trains', 0, 0, 0), -- LEAF
  (502, 'Transgender', 0, 0, 0), -- LEAF
  (503, 'Trauma', 0, 0, 0), -- LEAF
  (504, 'Travel', 0, 0, 0), -- LEAF
  (505, 'Tribal', 0, 0, 0), -- LEAF
  (506, 'Triple metre', 0, 0, 0), -- LEAF
  (507, 'Triumphant', 0, 0, 0), -- LEAF
  (508, 'Tropical', 0, 0, 0), -- LEAF
  (509, 'Twinkling', 0, 0, 0), -- LEAF
  (510, 'twinkling', 1, 0, 1), -- LEAF
  (511, 'Unaccompanied solo', 0, 0, 0), -- LEAF
  (512, 'Uncommon time signatures', 1, 0, 1), -- LEAF
  (513, 'Unrequited love', 0, 0, 0), -- LEAF
  (514, 'Uplifting', 0, 1, 0), -- 1 children
  (515, 'Urban', 0, 0, 0), -- LEAF
  (516, 'Utopian', 0, 0, 0), -- LEAF
  (517, 'Vampires', 0, 0, 0), -- LEAF
  (518, 'Vegetarianism', 0, 0, 0), -- LEAF
  (519, 'Vehicles', 0, 2, 0), -- 2 children
  (520, 'Vengeance', 0, 0, 0), -- LEAF
  (521, 'Video games', 1, 0, 1), -- LEAF
  (522, 'video games', 1, 0, 1), -- LEAF
  (523, 'Vikings', 0, 0, 0), -- LEAF
  (524, 'violence', 2, 0, 2), -- LEAF
  (525, 'Violence', 0, 2, 0), -- 2 children
  (526, 'Visual arts', 0, 3, 1), -- 3 children
  (527, 'Vocal chops', 0, 0, 0), -- LEAF
  (528, 'Vocal group', 0, 0, 0), -- LEAF
  (529, 'Vocals', 0, 26, 1), -- 26 children
  (530, 'Vulgar', 0, 0, 0), -- LEAF
  (531, 'vulgar', 1, 0, 1), -- LEAF
  (532, 'Wall of Sound', 0, 0, 0), -- LEAF
  (533, 'War', 0, 0, 0), -- LEAF
  (534, 'Warm', 0, 0, 0), -- LEAF
  (535, 'warm', 1, 0, 1), -- LEAF
  (536, 'Wetland', 0, 0, 0), -- LEAF
  (537, 'Whispering', 0, 0, 0), -- LEAF
  (538, 'Whistle register', 0, 0, 0), -- LEAF
  (539, 'Whistling', 0, 0, 0), -- LEAF
  (540, 'Wild West', 0, 0, 0), -- LEAF
  (541, 'Winter', 0, 0, 0), -- LEAF
  (542, 'winter', 2, 0, 2), -- LEAF
  (543, 'Womanhood', 0, 0, 0), -- LEAF
  (544, 'Wordplay', 0, 0, 0), -- LEAF
  (545, 'Work', 0, 2, 0), -- 2 children
  (546, 'Wrestling', 0, 0, 0), -- LEAF
  (547, 'Yarling', 0, 0, 0)  -- LEAF;


-- =============================================================================
-- 4. DESCRIPTOR TREE (descriptor_hierarchy) - every single edge
-- =============================================================================
INSERT INTO public.descriptor_hierarchy (parent_descriptor_id, child_descriptor_id) VALUES
  (7, 209), -- Afterlife  ->  Ghosts
  (23, 59), -- Animals  ->  Birds
  (23, 80), -- Animals  ->  Cats
  (23, 236), -- Animals  ->  Horses
  (23, 240), -- Animals  ->  Hunting
  (23, 368), -- Animals  ->  Pets
  (28, 30), -- Antidiscrimination  ->  Antiracism
  (40, 35), -- Atmosphere  ->  Apocalyptic
  (40, 54), -- Atmosphere  ->  Beach
  (40, 71), -- Atmosphere  ->  Bright
  (40, 82), -- Atmosphere  ->  Cavernous
  (40, 93), -- Atmosphere  ->  Cold
  (40, 109), -- Atmosphere  ->  Cozy
  (40, 120), -- Atmosphere  ->  Dark
  (40, 122), -- Atmosphere  ->  Daytime
  (40, 133), -- Atmosphere  ->  Desolate
  (40, 159), -- Atmosphere  ->  Epic
  (40, 161), -- Atmosphere  ->  Ethereal
  (40, 163), -- Atmosphere  ->  Evening
  (40, 200), -- Atmosphere  ->  Futuristic
  (40, 224), -- Atmosphere  ->  Hazy
  (40, 241), -- Atmosphere  ->  Hypnotic
  (40, 294), -- Atmosphere  ->  Martial
  (40, 298), -- Atmosphere  ->  Medieval
  (40, 321), -- Atmosphere  ->  Morning
  (40, 326), -- Atmosphere  ->  Mysterious
  (40, 330), -- Atmosphere  ->  Natural
  (40, 335), -- Atmosphere  ->  Nocturnal
  (40, 360), -- Atmosphere  ->  Party
  (40, 363), -- Atmosphere  ->  Pastoral
  (40, 366), -- Atmosphere  ->  Peaceful
  (40, 398), -- Atmosphere  ->  Pyschedelic
  (40, 417), -- Atmosphere  ->  Ritualistic
  (40, 438), -- Atmosphere  ->  Seasonal
  (40, 466), -- Atmosphere  ->  Space
  (40, 469), -- Atmosphere  ->  Spiritual
  (40, 482), -- Atmosphere  ->  Surreal
  (40, 484), -- Atmosphere  ->  Suspenseful
  (40, 505), -- Atmosphere  ->  Tribal
  (40, 509), -- Atmosphere  ->  Twinkling
  (40, 515), -- Atmosphere  ->  Urban
  (40, 534), -- Atmosphere  ->  Warm
  (57, 250), -- Betrayal  ->  Infidelity
  (76, 299), -- Calm  ->  Meditative
  (99, 12), -- Composition  ->  Aleatory
  (99, 74), -- Composition  ->  Call and response
  (99, 194), -- Composition  ->  Free rhythm
  (99, 202), -- Composition  ->  Gallop
  (99, 208), -- Composition  ->  Generative music
  (99, 245), -- Composition  ->  Improvisiation
  (99, 387), -- Composition  ->  Polyrhythm
  (99, 496), -- Composition  ->  Through-composed
  (99, 506), -- Composition  ->  Triple metre
  (99, 512), -- Composition  ->  Uncommon time signatures
  (102, 28), -- Conscious  ->  Antidiscrimination
  (112, 493), -- Crime  ->  Theft
  (120, 198), -- Dark  ->  Funereal
  (120, 248), -- Dark  ->  Infernal
  (120, 348), -- Dark  ->  Ominous
  (125, 234), -- Death  ->  Homicide
  (125, 479), -- Death  ->  Suicide
  (135, 146), -- Disaster  ->  Drought
  (147, 11), -- Drugs  ->  Alcohol
  (147, 29), -- Drugs  ->  Antidrug
  (147, 77), -- Drugs  ->  Cannabis
  (147, 90), -- Drugs  ->  Cocaine
  (147, 219), -- Drugs  ->  Hallucinogens
  (147, 332), -- Drugs  ->  Nicotine
  (147, 350), -- Drugs  ->  Opioids
  (150, 116), -- Dystopian  ->  Cyberpunk
  (155, 290), -- Energetic  ->  Manic
  (156, 1), -- Ensemble  ->  A cappella
  (156, 4), -- Ensemble  ->  Acoustic
  (156, 86), -- Ensemble  ->  Choral
  (156, 149), -- Ensemble  ->  Duet
  (156, 352), -- Ensemble  ->  Orchestral
  (156, 388), -- Ensemble  ->  Posse cut
  (156, 511), -- Ensemble  ->  Unaccompanied solo
  (156, 528), -- Ensemble  ->  Vocal group
  (171, 358), -- Family  ->  Parenthood
  (176, 105), -- Fashion  ->  Cosmetics
  (192, 49), -- Form  ->  Ballad
  (192, 101), -- Form  ->  Concept album
  (192, 138), -- Form  ->  Diss
  (192, 156), -- Form  ->  Ensemble
  (192, 301), -- Form  ->  Medley
  (192, 317), -- Form  ->  Monologue
  (192, 343), -- Form  ->  Novelty
  (192, 359), -- Form  ->  Parody
  (192, 362), -- Form  ->  Pastiche
  (192, 440), -- Form  ->  Section
  (192, 452), -- Form  ->  Silence
  (192, 455), -- Form  ->  Skit
  (192, 480), -- Form  ->  Suite
  (206, 182), -- Gender  ->  Feminism
  (206, 207), -- Gender  ->  Gender dysphoria
  (206, 289), -- Gender  ->  Manhood
  (206, 339), -- Gender  ->  Nonbinary
  (206, 502), -- Gender  ->  Transgender
  (206, 543), -- Gender  ->  Womanhood
  (221, 215), -- Harsh vocals  ->  Growling
  (221, 374), -- Harsh vocals  ->  Pig squealing
  (221, 450), -- Harsh vocals  ->  Shrieking
  (226, 136), -- Health  ->  Disease
  (226, 186), -- Health  ->  Fitness
  (226, 251), -- Health  ->  Injury
  (226, 309), -- Health  ->  Mental health
  (226, 458), -- Health  ->  Sobriety
  (232, 78), -- Holiday  ->  Carnaval
  (232, 88), -- Holiday  ->  Christmas
  (232, 217), -- Holiday  ->  Halloween
  (235, 106), -- Horror  ->  Cosmic horror
  (238, 121), -- Humorous  ->  Dark humor
  (243, 27), -- Ideology  ->  Anticonsumerism
  (243, 31), -- Ideology  ->  Antireligious
  (243, 182), -- Ideology  ->  Feminism
  (243, 354), -- Ideology  ->  Pacifism
  (243, 355), -- Ideology  ->  Pagan
  (243, 385), -- Ideology  ->  Political
  (243, 410), -- Ideology  ->  Religious
  (243, 429), -- Ideology  ->  Satanism
  (243, 518), -- Ideology  ->  Vegetarianism
  (245, 195), -- Improvisiation  ->  Freestyle
  (245, 261), -- Improvisiation  ->  Jamming
  (258, 408), -- Introspective  ->  Regret
  (269, 61), -- LGBTQ  ->  Bisexual
  (269, 205), -- LGBTQ  ->  Gay
  (269, 266), -- LGBTQ  ->  Lesbian
  (269, 339), -- LGBTQ  ->  Nonbinary
  (269, 502), -- LGBTQ  ->  Transgender
  (271, 58), -- Literature  ->  Biblical
  (271, 94), -- Literature  ->  Comics
  (280, 69), -- Love  ->  Breakup
  (280, 250), -- Love  ->  Infidelity
  (280, 277), -- Love  ->  Long-distance relationship
  (280, 513), -- Love  ->  Unrequited love
  (285, 91), -- Lyrics  ->  Code-mixing
  (285, 134), -- Lyrics  ->  Dialogue
  (285, 270), -- Lyrics  ->  List song
  (285, 284), -- Lyrics  ->  Lyrical dissonance
  (285, 328), -- Lyrics  ->  Narrative
  (285, 475), -- Lyrics  ->  Stream of consciousness
  (285, 500), -- Lyrics  ->  Tone
  (285, 544), -- Lyrics  ->  Wordplay
  (286, 210), -- Macabre  ->  Gore
  (293, 143), -- Marriage  ->  Divorce
  (305, 464), -- Mellow  ->  Soothing
  (309, 5), -- Mental health  ->  Addiction
  (309, 207), -- Mental health  ->  Gender dysphoria
  (309, 503), -- Mental health  ->  Trauma
  (316, 203), -- Money  ->  Gambling
  (316, 389), -- Money  ->  Poverty
  (319, 517), -- Monsters  ->  Vampires
  (320, 10), -- Mood  ->  Aggressive
  (320, 21), -- Mood  ->  Angry
  (320, 33), -- Mood  ->  Anxious
  (320, 63), -- Mood  ->  Bittersweet
  (320, 76), -- Mood  ->  Calm
  (320, 141), -- Mood  ->  Disturbing
  (320, 155), -- Mood  ->  Energetic
  (320, 220), -- Mood  ->  Happy
  (320, 268), -- Mood  ->  Lethargic
  (320, 279), -- Mood  ->  Longing
  (320, 305), -- Mood  ->  Mellow
  (320, 361), -- Mood  ->  Passionate
  (320, 380), -- Mood  ->  Playful
  (320, 399), -- Mood  ->  Quirky
  (320, 420), -- Mood  ->  Romantic
  (320, 423), -- Mood  ->  Sad
  (320, 433), -- Mood  ->  Scary
  (320, 443), -- Mood  ->  Sensual
  (320, 444), -- Mood  ->  Sentimental
  (320, 514), -- Mood  ->  Uplifting
  (330, 38), -- Natural  ->  Aquatic
  (330, 132), -- Natural  ->  Desert
  (330, 191), -- Natural  ->  Forest
  (330, 211), -- Natural  ->  Grassland
  (330, 322), -- Natural  ->  Mountains
  (330, 402), -- Natural  ->  Rain
  (330, 474), -- Natural  ->  Storm
  (330, 508), -- Natural  ->  Tropical
  (330, 536), -- Natural  ->  Wetland
  (331, 23), -- Nature  ->  Animals
  (331, 165), -- Nature  ->  Evironmentalism
  (331, 378), -- Nature  ->  Plants
  (341, 237), -- Nonlexical vocables  ->  Humming
  (341, 434), -- Nonlexical vocables  ->  Scat singing
  (357, 209), -- Paranormal  ->  Ghosts
  (369, 166), -- Philosophical  ->  Existential
  (369, 334), -- Philosophical  ->  Nihilistic
  (378, 188), -- Plants  ->  Flowers
  (385, 18), -- Political  ->  Anarchism
  (385, 26), -- Political  ->  Anti-authoritarian
  (385, 103), -- Political  ->  Conservatism
  (385, 165), -- Political  ->  Evironmentalism
  (385, 329), -- Political  ->  Nationalism
  (385, 393), -- Political  ->  Propaganda
  (385, 394), -- Political  ->  Protest
  (385, 414), -- Political  ->  Revolution
  (385, 459), -- Political  ->  Socialism
  (391, 274), -- Production  ->  Lobit
  (391, 424), -- Production  ->  Sampling
  (391, 532), -- Production  ->  Wall of Sound
  (410, 48), -- Religious  ->  Bahá'í
  (410, 72), -- Religious  ->  Buddhist
  (410, 87), -- Religious  ->  Christian
  (410, 230), -- Religious  ->  Hindu
  (410, 259), -- Religious  ->  Islamic
  (410, 260), -- Religious  ->  Jain
  (410, 262), -- Religious  ->  Judiac
  (410, 404), -- Religious  ->  Rastafari
  (410, 451), -- Religious  ->  Sikh
  (416, 67), -- Rhythmic  ->  Bouncy
  (416, 89), -- Rhythmic  ->  Chugging
  (416, 381), -- Rhythmic  ->  Plodding
  (416, 397), -- Rhythmic  ->  Punchy
  (416, 473), -- Rhythmic  ->  Stomping
  (423, 131), -- Sad  ->  Depressive
  (423, 276), -- Sad  ->  Lonely
  (423, 303), -- Sad  ->  Melancholic
  (423, 461), -- Sad  ->  Sombre
  (424, 527), -- Sampling  ->  Vocal chops
  (437, 116), -- Science fiction  ->  Cyberpunk
  (438, 45), -- Seasonal  ->  Autumn
  (438, 471), -- Seasonal  ->  Spring
  (438, 481), -- Seasonal  ->  Summer
  (438, 541), -- Seasonal  ->  Winter
  (440, 254), -- Section  ->  Interlude
  (440, 257), -- Section  ->  Intro
  (440, 323), -- Section  ->  Movement
  (440, 353), -- Section  ->  Outro
  (440, 413), -- Section  ->  Reprise
  (456, 145), -- Sleep  ->  Dreams
  (470, 39), -- Sports  ->  Association football
  (470, 50), -- Sports  ->  Baseball
  (470, 51), -- Sports  ->  Basketball
  (470, 68), -- Sports  ->  Boxing
  (470, 400), -- Sports  ->  Racing
  (470, 454), -- Sports  ->  Skateboarding
  (470, 546), -- Sports  ->  Wrestling
  (476, 22), -- Style  ->  Angular
  (476, 25), -- Style  ->  Anthemic
  (476, 42), -- Style  ->  Atmospheric
  (476, 44), -- Style  ->  Atonal
  (476, 46), -- Style  ->  Avant-garde
  (476, 52), -- Style  ->  Bassy
  (476, 73), -- Style  ->  Buzzy
  (476, 84), -- Style  ->  Chaotic
  (476, 97), -- Style  ->  Complex
  (476, 110), -- Style  ->  Crackly
  (476, 128), -- Style  ->  Dense
  (476, 139), -- Style  ->  Dissonant
  (476, 152), -- Style  ->  Eclectic
  (476, 193), -- Style  ->  Four on the floor
  (476, 201), -- Style  ->  Fuzzy
  (476, 228), -- Style  ->  Heavy
  (476, 253), -- Style  ->  Instrumental
  (476, 272), -- Style  ->  Lo-fi
  (476, 282), -- Style  ->  Lush
  (476, 296), -- Style  ->  Maximalist
  (476, 306), -- Style  ->  Melodic
  (476, 310), -- Style  ->  Microtonal
  (476, 312), -- Style  ->  Minimalistic
  (476, 318), -- Style  ->  Monophonic
  (476, 324), -- Style  ->  Muffled
  (476, 337), -- Style  ->  Noisy
  (476, 373), -- Style  ->  Piercing
  (476, 386), -- Style  ->  Polyphonic
  (476, 392), -- Style  ->  Progressive
  (476, 405), -- Style  ->  Raw
  (476, 412), -- Style  ->  Repetitive
  (476, 416), -- Style  ->  Rhythmic
  (476, 457), -- Style  ->  Smooth
  (476, 460), -- Style  ->  Soft
  (476, 468), -- Style  ->  Sparse
  (476, 472), -- Style  ->  Squelchy
  (476, 487), -- Style  ->  Technical
  (476, 492), -- Style  ->  Theatrical
  (476, 497), -- Style  ->  Ticking
  (489, 64), -- Technique  ->  Blast beats
  (489, 99), -- Technique  ->  Composition
  (489, 256), -- Technique  ->  Interpolation
  (489, 265), -- Technique  ->  Leitmotif
  (489, 391), -- Technique  ->  Production
  (489, 421), -- Technique  ->  Rubato
  (490, 419), -- Technology  ->  Robots
  (494, 2), -- Theme  ->  About music
  (494, 3), -- Theme  ->  Abstract
  (494, 6), -- Theme  ->  Adolescence
  (494, 7), -- Theme  ->  Afterlife
  (494, 8), -- Theme  ->  Ageing
  (494, 14), -- Theme  ->  Alienation
  (494, 15), -- Theme  ->  Aliens
  (494, 16), -- Theme  ->  Alter ego
  (494, 37), -- Theme  ->  Apology
  (494, 55), -- Theme  ->  Beauty
  (494, 57), -- Theme  ->  Betrayal
  (494, 60), -- Theme  ->  Birthday
  (494, 66), -- Theme  ->  Boredom
  (494, 75), -- Theme  ->  Callback
  (494, 85), -- Theme  ->  Childhood
  (494, 95), -- Theme  ->  Community
  (494, 102), -- Theme  ->  Conscious
  (494, 104), -- Theme  ->  Conspiracy
  (494, 107), -- Theme  ->  Courage
  (494, 112), -- Theme  ->  Crime
  (494, 118), -- Theme  ->  Dancing
  (494, 125), -- Theme  ->  Death
  (494, 126), -- Theme  ->  Decay
  (494, 135), -- Theme  ->  Disaster
  (494, 137), -- Theme  ->  Dishonesty
  (494, 144), -- Theme  ->  Domestic
  (494, 147), -- Theme  ->  Drugs
  (494, 150), -- Theme  ->  Dystopian
  (494, 153), -- Theme  ->  Educational
  (494, 157), -- Theme  ->  Entertainment industry
  (494, 158), -- Theme  ->  Envy
  (494, 160), -- Theme  ->  Escapism
  (494, 164), -- Theme  ->  Everyday life
  (494, 167), -- Theme  ->  Failure
  (494, 168), -- Theme  ->  Fairy tale
  (494, 170), -- Theme  ->  Fame
  (494, 171), -- Theme  ->  Family
  (494, 172), -- Theme  ->  Fans
  (494, 173), -- Theme  ->  Fantasy
  (494, 174), -- Theme  ->  Farewell
  (494, 176), -- Theme  ->  Fashion
  (494, 184), -- Theme  ->  Fire
  (494, 185), -- Theme  ->  Fishing
  (494, 187), -- Theme  ->  Flirting
  (494, 189), -- Theme  ->  Folklore
  (494, 190), -- Theme  ->  Food
  (494, 196), -- Theme  ->  Friendship
  (494, 206), -- Theme  ->  Gender
  (494, 212), -- Theme  ->  Gratitude
  (494, 213), -- Theme  ->  Greed
  (494, 214), -- Theme  ->  Grief
  (494, 216), -- Theme  ->  Guns
  (494, 225), -- Theme  ->  Healing
  (494, 226), -- Theme  ->  Health
  (494, 229), -- Theme  ->  Hedonism
  (494, 232), -- Theme  ->  Holiday
  (494, 233), -- Theme  ->  Homesickness
  (494, 235), -- Theme  ->  Horror
  (494, 243), -- Theme  ->  Ideology
  (494, 246), -- Theme  ->  Indigeneity
  (494, 247), -- Theme  ->  Individuality
  (494, 255), -- Theme  ->  Internet
  (494, 258), -- Theme  ->  Introspective
  (494, 263), -- Theme  ->  Law
  (494, 264), -- Theme  ->  Leisure
  (494, 269), -- Theme  ->  LGBTQ
  (494, 271), -- Theme  ->  Literature
  (494, 280), -- Theme  ->  Love
  (494, 281), -- Theme  ->  Loyalty
  (494, 286), -- Theme  ->  Macabre
  (494, 292), -- Theme  ->  Maritime
  (494, 293), -- Theme  ->  Marriage
  (494, 295), -- Theme  ->  Mathematics
  (494, 307), -- Theme  ->  Memory
  (494, 311), -- Theme  ->  Migration
  (494, 316), -- Theme  ->  Money
  (494, 319), -- Theme  ->  Monsters
  (494, 327), -- Theme  ->  Mythology
  (494, 331), -- Theme  ->  Nature
  (494, 333), -- Theme  ->  Nightlife
  (494, 342), -- Theme  ->  Nostalgia
  (494, 344), -- Theme  ->  Obsession
  (494, 345), -- Theme  ->  Occult
  (494, 347), -- Theme  ->  Older adulthood
  (494, 356), -- Theme  ->  Paranoia
  (494, 357), -- Theme  ->  Paranormal
  (494, 364), -- Theme  ->  Patriotic
  (494, 369), -- Theme  ->  Philosophical
  (494, 371), -- Theme  ->  Phones
  (494, 375), -- Theme  ->  Pirates
  (494, 383), -- Theme  ->  Police
  (494, 390), -- Theme  ->  Prison
  (494, 401), -- Theme  ->  Radio
  (494, 409), -- Theme  ->  Rejection
  (494, 435), -- Theme  ->  School
  (494, 436), -- Theme  ->  Science
  (494, 437), -- Theme  ->  Science fiction
  (494, 439), -- Theme  ->  Secrets
  (494, 441), -- Theme  ->  Self-hatred
  (494, 442), -- Theme  ->  Self-love
  (494, 447), -- Theme  ->  Sexual
  (494, 448), -- Theme  ->  Shamanism
  (494, 449), -- Theme  ->  Shopping
  (494, 456), -- Theme  ->  Sleep
  (494, 470), -- Theme  ->  Sports
  (494, 477), -- Theme  ->  Suburban
  (494, 478), -- Theme  ->  Success
  (494, 490), -- Theme  ->  Technology
  (494, 491), -- Theme  ->  Television
  (494, 498), -- Theme  ->  Time
  (494, 504), -- Theme  ->  Travel
  (494, 516), -- Theme  ->  Utopian
  (494, 519), -- Theme  ->  Vehicles
  (494, 520), -- Theme  ->  Vengeance
  (494, 521), -- Theme  ->  Video games
  (494, 523), -- Theme  ->  Vikings
  (494, 525), -- Theme  ->  Violence
  (494, 526), -- Theme  ->  Visual arts
  (494, 533), -- Theme  ->  War
  (494, 540), -- Theme  ->  Wild West
  (494, 545), -- Theme  ->  Work
  (500, 17), -- Tone  ->  Altruistic
  (500, 34), -- Tone  ->  Apathetic
  (500, 65), -- Tone  ->  Boastful
  (500, 81), -- Tone  ->  Cautionary
  (500, 96), -- Tone  ->  Compassionate
  (500, 114), -- Tone  ->  Cryptic
  (500, 117), -- Tone  ->  Cynical
  (500, 222), -- Tone  ->  Hateful
  (500, 238), -- Tone  ->  Humorous
  (500, 252), -- Tone  ->  Insecure
  (500, 308), -- Tone  ->  Menacing
  (500, 314), -- Tone  ->  Misanthropic
  (500, 351), -- Tone  ->  Optimistic
  (500, 367), -- Tone  ->  Pessimistic
  (500, 382), -- Tone  ->  Poetic
  (500, 395), -- Tone  ->  Provocative
  (500, 407), -- Tone  ->  Rebellious
  (500, 426), -- Tone  ->  Sarcastic
  (500, 427), -- Tone  ->  Sassy
  (500, 431), -- Tone  ->  Satirical
  (500, 445), -- Tone  ->  Serious
  (500, 530), -- Tone  ->  Vulgar
  (514, 507), -- Uplifting  ->  Triumphant
  (519, 79), -- Vehicles  ->  Cars
  (519, 501), -- Vehicles  ->  Trains
  (525, 210), -- Violence  ->  Gore
  (525, 234), -- Violence  ->  Homicide
  (526, 24), -- Visual arts  ->  Anime and manga
  (526, 94), -- Visual arts  ->  Comics
  (526, 183), -- Visual arts  ->  Film
  (529, 19), -- Vocals  ->  Androgynous vocals
  (529, 56), -- Vocals  ->  Belting
  (529, 113), -- Vocals  ->  Crooning
  (529, 123), -- Vocals  ->  Deadpan
  (529, 169), -- Vocals  ->  Falsetto
  (529, 180), -- Vocals  ->  Female vocalist
  (529, 204), -- Vocals  ->  Gang vocals
  (529, 221), -- Vocals  ->  Harsh vocals
  (529, 288), -- Vocals  ->  Male vocalist
  (529, 340), -- Vocals  ->  Nonbinary vocalist
  (529, 341), -- Vocals  ->  Nonlexical vocables
  (529, 376), -- Vocals  ->  Pitched-down vocals
  (529, 377), -- Vocals  ->  Pitched-up vocals
  (529, 453), -- Vocals  ->  Sing-rapping
  (529, 486), -- Vocals  ->  Talk-singing
  (529, 495), -- Vocals  ->  Throat singing
  (529, 499), -- Vocals  ->  Toasting
  (529, 537), -- Vocals  ->  Whispering
  (529, 538), -- Vocals  ->  Whistle register
  (529, 539), -- Vocals  ->  Whistling
  (529, 547), -- Vocals  ->  Yarling
  (545, 175), -- Work  ->  Farming
  (545, 313)  -- Work  ->  Mining;


-- =============================================================================
-- 5. IDENTITY SEQUENCES
-- =============================================================================
-- The four base tables (genres, descriptors, artists, records) use GENERATED
-- ALWAYS AS IDENTITY columns backed by internal sequences. If this seed is ever
-- applied to a brand-new empty database (never the live one), the identity
-- counters must be advanced past the highest inserted id so future inserts do
-- not collide:
--   SELECT setval(pg_get_serial_sequence('genres','genre_id'),
--                 (SELECT MAX(genre_id) FROM genres));
--   SELECT setval(pg_get_serial_sequence('descriptors','descriptor_id'),
--                 (SELECT MAX(descriptor_id) FROM descriptors));
COMMIT;
