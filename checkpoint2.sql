
-- Drop existing tables
DROP TABLE IF EXISTS list_albums;
DROP TABLE IF EXISTS album_genres;
DROP TABLE IF EXISTS album_artists;
DROP TABLE IF EXISTS user_follows;
DROP TABLE IF EXISTS logs;
DROP TABLE IF EXISTS lists;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS users;

-- Create Users Table
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    user_bio TEXT,
    join_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create Artists Table
CREATE TABLE artists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    artist_bio TEXT
);

-- Create Albums Table
CREATE TABLE albums (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    release_year INTEGER,
    cover_image TEXT
);

-- Create Genres Table
CREATE TABLE genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);

-- Create Lists Table
CREATE TABLE lists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_public INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Logs Table
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    album_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    listened_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_relistened INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE
);

-- Create User Follows Junction Table (M:N)
CREATE TABLE user_follows (
    follower_id INTEGER,
    following_id INTEGER,
    follow_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE,
    CHECK (follower_id != following_id)
);

-- Create Album-Artists Junction Table (M:N)
CREATE TABLE album_artists (
    album_id INTEGER,
    artist_id INTEGER,
    PRIMARY KEY (album_id, artist_id),
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artists(id) ON DELETE CASCADE
);

-- Create Album-Genres Junction Table (M:N)
CREATE TABLE album_genres (
    album_id INTEGER,
    genre_id INTEGER,
    PRIMARY KEY (album_id, genre_id),
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

-- Create List-Albums Junction Table (M:N)
CREATE TABLE list_albums (
    list_id INTEGER,
    album_id INTEGER,
    position INTEGER,
    PRIMARY KEY (list_id, album_id),
    FOREIGN KEY (list_id) REFERENCES lists(id) ON DELETE CASCADE,
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE
);

--------- INSERT ALBUMS ---------
INSERT INTO albums (title, release_year, cover_image) VALUES
 ('The Velvet Underground & Nico', 1967, 'albumCovers/vu_nico.jpg'),
   ('Loaded', 1970, 'albumCovers/loaded.jpg'),
   ('Transformer', 1972, 'albumCovers/transformer.jpg'),
   ('Berlin', 1973, 'albumCovers/berlin.jpg'),
   ('Hunky Dory', 1971, 'albumCovers/hunky_dory.jpg'),
   ('Ziggy Stardust', 1972, 'albumCovers/ziggy_stardust.jpg'),
   ('The Dark Side of the Moon', 1973, 'albumCovers/dark_side.jpg'),
   ('Wish You Were Here', 1975, 'albumCovers/wish_you_were_here.jpg'),
   ('Animals', 1977, 'albumCovers/animals.jpg'),
   ('Harvest', 1972, 'albumCovers/harvest.jpg'),
   ('After the Gold Rush', 1970, 'albumCovers/after_the_gold_rush.jpg'),
   ('Rumours', 1977, 'albumCovers/rumours.jpg'),
   ('Tapestry', 1971, 'albumCovers/tapestry.jpg'),
   ('Bridge Over Troubled Water', 1970, 'albumCovers/bridge_over_troubled_water.jpg'),
   ('Goodbye Yellow Brick Road', 1973, 'albumCovers/goodbye_ybr.jpg'),
   ('Blood on the Tracks', 1975, 'albumCovers/blood_on_the_tracks.jpg'),
   ('The Doors', 1967, 'albumCovers/the_doors.jpg'),
   ('Morrison Hotel', 1970, 'albumCovers/morrison_hotel.jpg'),
   ('Let It Bleed', 1969, 'albumCovers/let_it_bleed.jpg'),
   ('Sticky Fingers', 1971, 'albumCovers/sticky_fingers.jpg'),
   ('Tea for the Tillerman', 1970, 'albumCovers/tea_for_the_tillerman.jpg'),
   ('Blue', 1971, 'albumCovers/blue_joni.jpg'),
   ('Court and Spark', 1974, 'albumCovers/court_and_spark.jpg'),
   ('Paris 1919', 1973, 'albumCovers/paris_1919.jpg'),
   ('Songs of Leonard Cohen', 1967, 'albumCovers/songs_of_leonard_cohen.jpg'),
   ('The Queen Is Dead', 1986, 'albumCovers/the_queen_is_dead.jpg'),
   ('Strangeways, Here We Come', 1987, 'albumCovers/strangeways.jpg'),
   ('Louder Than Bombs', 1987, 'albumCovers/louder_than_bombs.jpg'),
   ('OK Computer', 1997, 'albumCovers/ok_computer.jpg'),
   ('Kid A', 2000, 'albumCovers/kid_a.jpg'),
   ('In Rainbows', 2007, 'albumCovers/in_rainbows.jpg'),
   ('The Bends', 1995, 'albumCovers/the_bends.jpg'),
   ('Fetch the Bolt Cutters', 2020, 'albumCovers/fetch_the_bolt_cutters.jpg'),
   ('When the Pawn...', 1999, 'albumCovers/when_the_pawn.jpg'),
   ('Extraordinary Machine', 2005, 'albumCovers/extraordinary_machine.jpg'),
   ('Grace', 1994, 'albumCovers/grace.jpg'),
   ('Either/Or', 1997, 'albumCovers/either_or.jpg'),
   ('XO', 1998, 'albumCovers/xo.jpg'),
   ('For Emma, Forever Ago', 2007, 'albumCovers/for_emma.jpg'),
   ('Carrie & Lowell', 2015, 'albumCovers/carrie_and_lowell.jpg'),
   ('Let It Be', 1984, 'albumCovers/let_it_be_replacements.jpg'),
   ('Tim', 1985, 'albumCovers/tim.jpg'),
   ('Marquee Moon', 1977, 'albumCovers/marquee_moon.jpg'),
   ('Unknown Pleasures', 1979, 'albumCovers/unknown_pleasures.jpg'),
   ('The Soft Bulletin', 1999, 'albumCovers/the_soft_bulletin.jpg'),
   ('The Glow Pt. 2', 2001, 'albumCovers/the_glow_pt2.jpg'),
   ('Pink Moon', 1972, 'albumCovers/pink_moon.jpg'),
   ('Dusty in Memphis', 1969, 'albumCovers/dusty_in_memphis.jpg'),
   ('Odessey and Oracle', 1968, 'albumCovers/odessey_and_oracle.jpg'),
   ('Forever Changes', 1967, 'albumCovers/forever_changes.jpg');

--------- INSERT ARTISTS ---------
INSERT INTO artists (name) VALUES
('The Velvet Underground'),
('Lou Reed'),
('David Bowie'),
('Pink Floyd'),
('Neil Young'),
('Fleetwood Mac'),
('Carole King'),
('Simon & Garfunkel'),
('Bob Dylan'),
('The Doors'),
('The Rolling Stones'),
('Cat Stevens'),
('Joni Mitchell'),
('Leonard Cohen'),
('The Smiths'),
('Radiohead'),
('Fiona Apple'),
('Jeff Buckley'),
('Elliott Smith'),
('Bon Iver'),
('Sufjan Stevens'),
('The Replacements'),
('Television'),
('Joy Division'),
('The Flaming Lips'),
('The Microphones'),
('Nick Drake'),
('Dusty Springfield'),
('The Zombies'),
('Love'),

INSERT INTO artists (name) VALUES
('John Cale'),

-- EXTRA 30 ARTISTS (similar genre)
('The Beatles'),
('The Kinks'),
('The Who'),
('Roxy Music'),
('Talking Heads'),
('Patti Smith'),
('Sonic Youth'),
('Arcade Fire'),
('The Cure'),
('The National'),
('Wilco'),
('Modest Mouse'),
('Neutral Milk Hotel'),
('Phoebe Bridgers'),
('Big Thief'),
('Sharon Van Etten'),
('Mazzy Star'),
('PJ Harvey'),
('The Smashing Pumpkins'),
('The Cranberries'),
('Yo La Tengo'),
('Built to Spill'),
('Slowdive'),
('My Bloody Valentine'),
('Cocteau Twins'),
('Interpol'),
('The Strokes'),
('Arctic Monkeys'),
('Mitski'),
('Angel Olsen');

--------- INSERT ALBUM_ARTISTS ---------
INSERT INTO album_artists (album_id, artist_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 2),
(5, 3),
(6, 3),
(7, 4),
(8, 4),
(9, 4),
(10, 5),
(11, 5),
(12, 6),
(13, 7),
(14, 8),
(15, 3),
(16, 9),
(17, 10),
(18, 10),
(19, 11),
(20, 11),
(21, 12),
(22, 13),
(23, 13),
(24, 61),
(25, 14),
(26, 15),
(27, 15),
(28, 15),
(29, 16),
(30, 16),
(31, 16),
(32, 16),
(33, 17),
(34, 17),
(35, 17),
(36, 18),
(37, 19),
(38, 19),
(39, 20),
(40, 21),
(41, 22),
(42, 22),
(43, 23),
(44, 24),
(45, 25),
(46, 26),
(47, 27),
(48, 28),
(49, 29),
(50, 30);


--------- INSERT GENRES ---------
INSERT INTO genres (name) VALUES
('Art Rock'),
('Proto-Punk'),
('Rock'),
('Glam Rock'),
('Art Pop'),
('Progressive Rock'),
('Folk Rock'),
('Soft Rock'),
('Singer-Songwriter'),
('Psychedelic Rock'),
('Blues Rock'),
('Folk Pop'),
('Indie Rock'),
('Alternative Rock'),
('Experimental Rock'),
('Baroque Pop'),
('Indie Folk'),
('Indie Pop'),
('Post-Punk'),
('Neo-Psychedelia'),
('Lo-Fi'),
('Folk'),
('Soul'),
('Psychedelic Pop');

--------- INSERT ALBUM_GENRES ---------
INSERT INTO album_genres (album_id, genre_id) VALUES
(1, 1), (1, 2),
(2, 3),
(3, 4),
(4, 1),
(5, 5), (5, 4),
(6, 4),
(7, 6),
(8, 6),
(9, 6),
(10, 7),
(11, 7),
(12, 8),
(13, 9),
(14, 7),
(15, 4), (15, 5),
(16, 7),
(17, 10),
(18, 11),
(19, 3),
(20, 3),
(21, 7),
(22, 9),
(23, 12),
(24, 1),
(25, 9),
(26, 13),
(27, 13),
(28, 13),
(29, 14),
(30, 15),
(31, 14),
(32, 14),
(33, 5),
(34, 5),
(35, 16),
(36, 14),
(37, 17),
(38, 18),
(39, 17),
(40, 17),
(41, 14),
(42, 14),
(43, 19),
(44, 19),
(45, 20),
(46, 17), (46, 21),
(47, 22),
(48, 23),
(49, 24),
(50, 10);

--------- INSERT USERS ---------
INSERT INTO users (username, email, password_hash) VALUES
('xlizbethxx', 'lizbethp9104@gmail.com', '$2b$10$placeholder1'),
('jaasminelau', 'jasmine.gclau@gmail.com', '$2b$10$placeholder2'),
('maariacelis', 'maria.celis98@gmail.com', '$2b$10$placeholder3'),
('sofiyalyn', 'sofiyalyn01@gmail.com', '$2b$10$placeholder4'),
('alexcrescent', 'alex.crescent@gmail.com', '$2b$10$placeholder5'),
('viviennecho', 'vivienne.cho@gmail.com', '$2b$10$placeholder6'),
('katarinavq', 'katarina.vq@gmail.com', '$2b$10$placeholder7'),
('natalynnm', 'natalynn.m@gmail.com', '$2b$10$placeholder8'),
('selenaaiko', 'selenaaiko@gmail.com', '$2b$10$placeholder9'),
('ameliesei', 'ameliesei@gmail.com', '$2b$10$placeholder10'),
('emiliasage', 'emilia.sage04@gmail.com', '$2b$10$placeholder11'),
('noelleash', 'noelle.ash02@gmail.com', '$2b$10$placeholder12'),
('isabellekai', 'isabelle.kai@gmail.com', '$2b$10$placeholder13'),
('lydiasoel', 'lydia.soel@gmail.com', '$2b$10$placeholder14'),
('avrilmae', 'avril.mae23@gmail.com', '$2b$10$placeholder15');


--------- INSERT USER_FOLLOWS ---------
INSERT INTO user_follows (follower_id, following_id) VALUES
(1, 2),
(1, 4),
(1, 6),
(2, 1),
(2, 3),
(2, 5),
(3, 1),
(3, 6),
(3, 8),
(4, 1),
(4, 7),
(4, 9),
(5, 2),
(5, 6),
(5, 10),
(6, 1),
(6, 3),
(6, 11),
(7, 4),
(7, 8),
(7, 12),
(8, 3),
(8, 9),
(8, 13),
(9, 4),
(9, 14),
(10, 5),
(10, 11),
(11, 6),
(11, 15);

--------- INSERT LOGS ---------
INSERT INTO logs (id, user_id, album_id, rating, review, listened_date) VALUES
(1, 1, 1, 5, 'this album makes me feel like im walking through a museum at 2am', '2025-01-04 14:21:10'),
(2, 3, 7, 4, 'i swear pink floyd reshaped my brain chemistry again', '2025-01-06 09:11:55'),
(3, 5, 33, 5, 'fiona apple is so real for this one omg', '2025-01-09 18:42:33'),
(4, 2, 16, 4, 'bob dylan yelling at me for 50 mins but in a comforting way', '2025-01-11 22:19:00'),
(5, 8, 29, 5, 'radiohead cured my seasonal depression for like 10 minutes', '2025-01-13 10:47:18'),
(6, 4, 22, 5, 'joni mitchell is basically therapy', '2025-01-14 16:22:59'),
(7, 7, 45, 4, 'the soft bulletin feels like floating in outer space but peacefully', '2025-01-15 20:15:40'),
(8, 9, 44, 5, 'this album makes me want to stare out a rainy window dramatically', '2025-01-18 07:33:25'),
(9, 10, 39, 5, 'bon iver really said cabin-in-the-woods heartbreak', '2025-01-20 19:58:17'),
(10, 6, 50, 4, 'this album feels like drinking tea in a haunted victorian house', '2025-01-22 12:44:03'),
(11, 11, 5, 5, 'david bowie you beautiful alien man', '2025-01-26 21:13:48'),
(12, 13, 12, 3, 'its good but also feels like a breakup i didnt consent to', '2025-01-28 13:03:59'),
(13, 14, 31, 5, 'in rainbows is literally liquid gold for my ears', '2025-02-01 08:56:41'),
(14, 15, 6, 4, 'ziggy stardust makes me want to wear glitter and ascend', '2025-02-02 23:17:14'),
(15, 1, 10, 5, 'harvest is so warm its like a hug from a forest', '2025-02-04 11:29:52'),
(16, 3, 24, 4, 'this album feels like foggy mornings and poetry', '2025-02-05 17:47:36'),
(17, 4, 19, 4, 'the rolling stones invented swagger i fear', '2025-02-06 15:08:01'),
(18, 5, 25, 5, 'leonard cohen makes me want to write a novel at 3am', '2025-02-08 09:41:57'),
(19, 7, 48, 5, 'dusty springfield mothered fr', '2025-02-09 20:22:22'),
(20, 8, 14, 4, 'so soothing i forgot my responsibilities', '2025-02-12 18:55:39'),
(21, 2, 2, 3, NULL, '2025-02-14 14:33:16'),
(22, 9, 4, 5, 'lou reed being dramatic again and im here for it', '2025-02-16 10:20:44'),
(23, 10, 38, 4, 'elliott smith sounds like soft sadness and cinnamon', '2025-02-17 13:11:02'),
(24, 12, 47, 5, 'nick drake = floating in a pink cloud of melancholy', '2025-02-18 08:23:55'),
(25, 6, 18, 4, 'doors music always feels like getting possessed a little', '2025-02-21 22:18:33'),
(26, 14, 43, 5, 'marquee moon is soooo ethereal pls', '2025-02-23 20:34:29'),
(27, 15, 13, 4, 'tapestry feels like soft sunlight', '2025-02-25 12:04:09'),
(28, 11, 9, 3, NULL, '2025-02-27 15:17:58'),
(29, 3, 49, 5, 'this album sounds like drinking lemonade in a garden', '2025-03-01 11:55:17'),
(30, 1, 11, 5, 'after the gold rush is perfection on earth', '2025-03-03 19:11:44'),
(31, 4, 33, 5, 'fiona apple read my diary and exposed me', '2025-03-05 07:45:22'),
(32, 7, 36, 5, 'jeff buckley please sing me to sleep every night', '2025-03-06 14:21:38'),
(33, 5, 15, 4, 'this album is so dramatic i love it', '2025-03-08 18:30:02'),
(34, 8, 23, 4, 'this feels like floating on a lake at dusk', '2025-03-10 10:59:49'),
(35, 2, 17, 3, NULL, '2025-03-11 12:18:44'),
(36, 10, 41, 5, 'the replacements ate this UP', '2025-03-12 17:58:27'),
(37, 9, 28, 4, 'the smiths are so dramatic i cant', '2025-03-14 09:35:50'),
(38, 6, 20, 5, 'sticky fingers goes soooo hard', '2025-03-15 22:44:19'),
(39, 13, 26, 4, 'moody, rainy, poetic—peak sad indie energy', '2025-03-17 15:01:33'),
(40, 12, 32, 5, 'the bends boosts my heart rate like cardio', '2025-03-20 08:28:11'),
(41, 15, 35, 4, 'this album feels like sitting in a vintage café writing poetry', '2025-03-22 21:13:07'),
(42, 7, 27, 4, 'so angsty so iconic', '2025-03-23 14:51:55'),
(43, 11, 3, 5, 'lou reed is such a vibe ngl', '2025-03-25 16:04:18'),
(44, 14, 34, 5, 'fiona sassing the world for 45 minutes straight', '2025-03-27 20:40:53'),
(45, 1, 30, 5, 'kid a makes me feel like a glitching robot but lovingly', '2025-03-29 11:06:44'),
(46, 4, 21, 4, 'cat stevens carrying the folk genre on his back', '2025-03-31 09:59:13'),
(47, 3, 37, 5, 'either/or is literally the blueprint for indie sadness', '2025-04-01 13:20:57'),
(48, 5, 40, 4, 'sufjan whispering directly into my soul again', '2025-04-03 18:29:02'),
(49, 8, 46, 5, 'this album sounds like fog in the woods', '2025-04-05 22:44:40'),
(50, 2, 42, 4, 'rocking out in my room like its 1985', '2025-04-07 10:12:33');

--------- INSERT LISTS ---------
INSERT INTO lists (id, user_id, name, is_public) VALUES
(1, 7,  'songs to stare at ceilings to', TRUE),
(2, 14, 'albums for dramatic walks', TRUE),
(3, 2,  'crying but in a cute way', FALSE),
(4, 11, 'music that fixed me temporarily', TRUE),
(5, 4,  'vibes for rainy window moments', TRUE),
(6, 9,  'soft songs for soft people', FALSE),
(7, 1,  'i am in my poetic phase', TRUE),
(8, 13, 'music that raised me fr', TRUE),
(9, 3,  'for when i want to vanish', FALSE),
(10, 12, 'songs that feel like warm tea', TRUE),
(11, 8,  'late night existential crisis', TRUE),
(12, 6,  'i am the main character', FALSE),
(13, 15, 'music for staring at nothing', TRUE),
(14, 10, 'pretty sounds for pretty days', TRUE),
(15, 5,  'sleepy girl soundtrack', FALSE),
(16, 3,  'albums that make me levitate', TRUE),
(17, 1,  'for driving nowhere at 1am', TRUE),
(18, 9,  'songs to feel mysterious to', FALSE),
(19, 12, 'my villain arc playlist', TRUE),
(20, 2,  'gentle tunes for fragile hearts', TRUE);

--------- INSERT LIST_ALBUMS ---------
INSERT INTO list_albums (list_id, album_id, position) VALUES
(1, 31, 1),
(1, 7, 2),
(1, 1, 3),
(2, 29, 1),
(2, 44, 2),
(2, 30, 3),
(2, 27, 4),
(3, 37, 1),
(3, 47, 2),
(3, 14, 3),
(4, 33, 1),
(4, 16, 2),
(4, 45, 3),
(4, 9, 4),
(5, 22, 1),
(5, 12, 2),
(5, 41, 3),
(6, 48, 1),
(6, 20, 2),
(7, 5, 1),
(7, 6, 2),
(7, 15, 3),
(7, 23, 4),
(8, 36, 1),
(8, 38, 2),
(8, 42, 3),
(8, 35, 4),
(9, 1, 1),
(9, 50, 2),
(10, 40, 1),
(10, 39, 2),
(10, 31, 3),
(11, 29, 1),
(11, 32, 2),
(11, 33, 3),
(11, 7, 4),
(12, 10, 1),
(12, 21, 2),
(13, 24, 1),
(13, 46, 2),
(13, 47, 3),
(13, 28, 4),
(14, 30, 1),
(14, 43, 2),
(14, 3, 3),
(15, 22, 1),
(15, 13, 2),
(15, 47, 3),
(15, 40, 4),
(16, 7, 1),
(16, 45, 2),
(16, 49, 3),
(17, 6, 1),
(17, 44, 2),
(17, 12, 3),
(18, 39, 1),
(18, 26, 2),
(18, 35, 3),
(19, 15, 1),
(19, 16, 2),
(19, 8, 3),
(20, 4, 1),
(20, 1, 2),
(20, 22, 3);


-- QUERY 1: Browse albums - all albums with artist info
SELECT a.id, a.title, a.release_year, ar.name AS artist_name
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
ORDER BY a.release_year DESC
LIMIT 20;

-- QUERY 2: Album details with ratings
SELECT a.title AS album_title, ar.name AS artist_name, a.release_year,
       AVG(l.rating) AS avg_rating, COUNT(l.id) AS total_reviews
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
LEFT JOIN logs l ON a.id = l.album_id
WHERE a.id = 7
GROUP BY a.id, a.title, ar.name, a.release_year;

-- QUERY 3: Log listening history - user's listening logs
SELECT u.username, a.title AS album_title, ar.name AS artist, 
       l.rating, l.listened_date
FROM logs l
JOIN users u ON l.user_id = u.id
JOIN albums a ON l.album_id = a.id
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
WHERE u.id = 1
ORDER BY l.listened_date DESC;

-- QUERY 4: Rate albums - top-rated albums
SELECT a.title, ar.name AS artist, AVG(l.rating) AS avg_rating, 
       COUNT(l.id) AS num_ratings
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
JOIN logs l ON a.id = l.album_id
GROUP BY a.id, a.title, ar.name
HAVING AVG(l.rating) >= 4.5
ORDER BY avg_rating DESC, num_ratings DESC;

-- QUERY 5: Review albums - recent reviews
SELECT u.username, a.title AS album_title, l.rating, 
       l.review, l.listened_date
FROM logs l
JOIN users u ON l.user_id = u.id
JOIN albums a ON l.album_id = a.id
WHERE l.review IS NOT NULL
ORDER BY l.listened_date DESC
LIMIT 15;

-- QUERY 6: Search music by album title
SELECT a.title, ar.name AS artist_name, a.release_year
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
WHERE a.title LIKE '%rainbow%'
ORDER BY a.release_year DESC;

-- QUERY 7: Search music by artist name
SELECT ar.name AS artist_name, a.title AS album_title, a.release_year
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
WHERE ar.name LIKE '%radio%'
ORDER BY a.release_year;

-- QUERY 8: Search users by username
SELECT username, email, user_bio, join_date
FROM users
WHERE username LIKE '%liz%';

-- QUERY 9: Follow users - get user's followers
SELECT u.username AS follower, uf.follow_date
FROM user_follows uf
JOIN users u ON uf.follower_id = u.id
WHERE uf.following_id = 1
ORDER BY uf.follow_date DESC;

-- QUERY 10: Follow users - get who user is following
SELECT u.username AS following, uf.follow_date
FROM user_follows uf
JOIN users u ON uf.following_id = u.id
WHERE uf.follower_id = 1
ORDER BY uf.follow_date DESC;

-- QUERY 11: Create lists - view user's lists
SELECT l.id, l.name, l.is_public, l.created_date,
       COUNT(la.album_id) AS album_count
FROM lists l
LEFT JOIN list_albums la ON l.id = la.list_id
WHERE l.user_id = 1
GROUP BY l.id, l.name, l.is_public, l.created_date
ORDER BY l.created_date DESC;

-- QUERY 12: View albums in a specific list
SELECT l.name AS list_name, a.title AS album_title, 
       ar.name AS artist_name, la.position
FROM list_albums la
JOIN lists l ON la.list_id = l.id
JOIN albums a ON la.album_id = a.id
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
WHERE l.id = 7
ORDER BY la.position;

-- QUERY 13: Browse public lists
SELECT u.username, l.name AS list_name, l.created_date,
       COUNT(la.album_id) AS album_count
FROM lists l
JOIN users u ON l.user_id = u.id
LEFT JOIN list_albums la ON l.id = la.list_id
WHERE l.is_public = 1
GROUP BY l.id, u.username, l.name, l.created_date
ORDER BY l.created_date DESC
LIMIT 10;

-- QUERY 14: Find albums by genre
SELECT a.title, ar.name AS artist, a.release_year, g.name AS genre
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
JOIN album_genres ag ON a.id = ag.album_id
JOIN genres g ON ag.genre_id = g.id
WHERE g.name = 'Indie Rock'
ORDER BY a.release_year DESC;

-- QUERY 15: Most active users (most logs)
SELECT u.username, COUNT(l.id) AS total_logs,
       AVG(l.rating) AS avg_rating_given
FROM users u
JOIN logs l ON u.id = l.user_id
GROUP BY u.id, u.username
ORDER BY total_logs DESC
LIMIT 10;

-- QUERY 16: Most popular albums (most logged)
SELECT a.title, ar.name AS artist, 
       COUNT(l.id) AS times_logged,
       AVG(l.rating) AS avg_rating
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
LEFT JOIN logs l ON a.id = l.album_id
GROUP BY a.id, a.title, ar.name
ORDER BY times_logged DESC
LIMIT 10;

-- QUERY 17: Albums released in specific year range
SELECT a.title, ar.name AS artist, a.release_year
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
WHERE a.release_year BETWEEN 1995 AND 2005
ORDER BY a.release_year;

-- QUERY 18: User activity feed (following users' recent logs)
SELECT u.username AS logged_by, a.title AS album_title, 
       l.rating, l.review, l.listened_date
FROM user_follows uf
JOIN logs l ON uf.following_id = l.user_id
JOIN users u ON l.user_id = u.id
JOIN albums a ON l.album_id = a.id
WHERE uf.follower_id = 1
ORDER BY l.listened_date DESC
LIMIT 20;

-- QUERY 19: Albums with multiple genres
SELECT a.title, ar.name AS artist,
       GROUP_CONCAT(g.name, ', ') AS genres
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
JOIN album_genres ag ON a.id = ag.album_id
JOIN genres g ON ag.genre_id = g.id
GROUP BY a.id, a.title, ar.name
HAVING COUNT(g.id) > 1
ORDER BY COUNT(g.id) DESC;

-- QUERY 20: Find users who haven't logged any albums
SELECT u.username, u.email, u.join_date
FROM users u
LEFT JOIN logs l ON u.id = l.user_id
WHERE l.id IS NULL;

-- QUERY 21: Albums by specific artist
SELECT a.title, a.release_year, 
       AVG(l.rating) AS avg_rating,
       COUNT(l.id) AS review_count
FROM albums a
JOIN album_artists aa ON a.id = aa.album_id
JOIN artists ar ON aa.artist_id = ar.id
LEFT JOIN logs l ON a.id = l.album_id
WHERE ar.name = 'Radiohead'
GROUP BY a.id, a.title, a.release_year
ORDER BY a.release_year;

-- QUERY 22: Genre statistics
SELECT g.name AS genre, 
       COUNT(DISTINCT ag.album_id) AS num_albums,
       AVG(l.rating) AS avg_rating
FROM genres g
JOIN album_genres ag ON g.id = ag.genre_id
LEFT JOIN logs l ON ag.album_id = l.album_id
GROUP BY g.id, g.name
ORDER BY num_albums DESC;

-- ============================================
-- DATA MODIFICATION STATEMENTS (14 TOTAL)
-- ============================================

-- INSERT 1: User logs a new album
INSERT INTO logs (user_id, album_id, rating, review, listened_date)
VALUES (1, 26, 5, 'the smiths never miss honestly', datetime('now'));

-- INSERT 2: User creates a new list
INSERT INTO lists (user_id, name, is_public)
VALUES (1, 'albums that changed my life', 1);

-- INSERT 3: Add album to list
INSERT INTO list_albums (list_id, album_id, position)
VALUES (21, 29, 1);

-- INSERT 4: User follows another user
INSERT INTO user_follows (follower_id, following_id)
VALUES (5, 7);

-- INSERT 5: Add new artist
INSERT INTO artists (name, artist_bio)
VALUES ('Taylor Swift', 'Grammy-winning singer-songwriter known for narrative lyrics');

-- INSERT 6: Add new album
INSERT INTO albums (title, release_year, cover_image)
VALUES ('folklore', 2020, 'albumCovers/folklore.jpg');

-- INSERT 7: Link album to artist
INSERT INTO album_artists (album_id, artist_id)
VALUES (51, 62);

-- INSERT 8: Add genre to album
INSERT INTO album_genres (album_id, genre_id)
VALUES (51, 17);

-- UPDATE 1: Update user bio
UPDATE users
SET user_bio = 'indie enthusiast and concert photographer'
WHERE id = 1;

-- UPDATE 2: Change album rating
UPDATE logs
SET rating = 5
WHERE id = 12;

-- UPDATE 3: Update review text
UPDATE logs
SET review = 'this album gets better with every listen'
WHERE id = 21;

-- UPDATE 4: Make list private
UPDATE lists
SET is_public = 0
WHERE id = 7;

-- UPDATE 5: Change album release year
UPDATE albums
SET release_year = 2001
WHERE id = 46;

-- UPDATE 6: Update artist bio
UPDATE artists
SET artist_bio = 'English rock band formed in 1985 and known for their jangly guitar sound'
WHERE id = 15;

-- DELETE 1: Remove album from list
DELETE FROM list_albums
WHERE list_id = 5 AND album_id = 41;

-- DELETE 2: User unfollows someone
DELETE FROM user_follows
WHERE follower_id = 1 AND follower_id = 4;

-- DELETE 3: Delete a review (keep log, remove review text)
UPDATE logs
SET review = NULL
WHERE id = 28;

-- DELETE 4: Remove a log entirely
DELETE FROM logs
WHERE id = 35;

-- DELETE 5: Delete an entire list
DELETE FROM lists
WHERE id = 18;