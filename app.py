from flask import Flask, render_template, request, redirect, url_for, session
import sqlite3

DB_PATH = "discoboxd.db"

app = Flask(__name__)
app.secret_key = "super_secret_for_demo"

def connect_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


@app.route("/")
def index():
    return redirect(url_for("albums"))


@app.route("/albums")
def albums():
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, title, release_year, cover_image
        FROM albums
        ORDER BY title ASC;
    """)
    albums = cur.fetchall()
    conn.close()

    return render_template("albums.html", albums=albums)


@app.route("/album/<int:album_id>")
def album_detail(album_id):
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("SELECT * FROM albums WHERE id = ?", (album_id,))
    album = cur.fetchone()
    if not album:
        conn.close()
        return "Album not found", 404

    cur.execute("""
        SELECT GROUP_CONCAT(ar.name, ', ') AS artists
        FROM artists ar
        JOIN album_artists aa ON ar.id = aa.artist_id
        WHERE aa.album_id = ?;
    """, (album_id,))
    artist_row = cur.fetchone()
    artist = artist_row["artists"] if artist_row["artists"] else "Unknown"

    cur.execute("""
        SELECT GROUP_CONCAT(g.name, ', ') AS genres
        FROM genres g
        JOIN album_genres ag ON g.id = ag.genre_id
        WHERE ag.album_id = ?;
    """, (album_id,))
    genre_row = cur.fetchone()
    genres = genre_row["genres"] if genre_row["genres"] else "Unknown"

    cur.execute("""
    SELECT ROUND(AVG(rating), 2) AS avg_rating
        FROM (
            SELECT rating
            FROM logs
            WHERE album_id = ?
            AND rating IS NOT NULL
            GROUP BY user_id
            HAVING listened_date = MAX(listened_date)
        );
        """, (album_id,))
    avg_row = cur.fetchone()
    avg_rating = round(avg_row["avg_rating"], 2) if avg_row["avg_rating"] is not None else None

    cur.execute("""
        SELECT u.id AS user_id,
               u.username,
               l.rating,
               l.review,
               l.listened_date
        FROM logs l
        JOIN users u ON l.user_id = u.id
        JOIN (
            SELECT user_id, MAX(listened_date) AS max_date
            FROM logs
            WHERE album_id = ?
              AND (rating IS NOT NULL OR review IS NOT NULL)
            GROUP BY user_id
        ) latest
          ON latest.user_id = l.user_id
         AND latest.max_date = l.listened_date
        WHERE l.album_id = ?
        ORDER BY l.listened_date DESC;
    """, (album_id, album_id))
    reviews = cur.fetchall()

    user_lists = []

    if session.get("user_id"):
        cur.execute("""
            SELECT id, name,
                (SELECT COUNT(*) FROM list_albums WHERE list_id = lists.id) AS album_count
            FROM lists
            WHERE user_id = ?
            ORDER BY created_date DESC;
        """, (session["user_id"],))
        user_lists = cur.fetchall()


    conn.close()

    return render_template(
    "album_details.html",
    album=album,
    artist=artist,
    genres=genres,
    avg_rating=avg_rating,
    reviews=reviews,
    user_lists=user_lists  
)


@app.route("/album/<int:album_id>/log", methods=["POST"])
def log_album(album_id):
    if not session.get("user_id"):
        return redirect(url_for("login"))

    user_id = session["user_id"]

    rating_raw = request.form.get("rating")
    review = request.form.get("review", "").strip()

    rating = None
    if rating_raw:
        try:
            rating = int(rating_raw)
        except:
            rating = None

    conn = connect_db()
    cur = conn.cursor()

    if rating is None and review == "":
        cur.execute("""
            INSERT INTO logs (user_id, album_id, rating, review, listened_date)
            VALUES (?, ?, NULL, NULL, datetime('now'));
        """, (user_id, album_id))

        session["success"] = "✅ Album logged as listened!"
        conn.commit()
        conn.close()
        return redirect(url_for("album_detail", album_id=album_id))


    if review and (rating is None or rating < 1 or rating > 5):
        session["error"] = "You must include a rating between 1 and 5 when writing a review."
        conn.close()
        return redirect(url_for("album_detail", album_id=album_id))

    if rating is not None and (rating < 1 or rating > 5):
        session["error"] = "Rating must be between 1 and 5."
        conn.close()
        return redirect(url_for("album_detail", album_id=album_id))

    cur.execute("""
        SELECT id
        FROM logs
        WHERE user_id = ?
          AND album_id = ?
          AND (rating IS NOT NULL OR review IS NOT NULL)
        ORDER BY listened_date DESC
        LIMIT 1;
    """, (user_id, album_id))
    existing = cur.fetchone()

    if existing:
        cur.execute("""
            UPDATE logs
            SET rating = ?,
                review = ?,
                listened_date = datetime('now')
            WHERE id = ?;
        """, (rating, review if review else None, existing["id"]))

        session["success"] = "✅ Rating / review updated!"
    else:
        cur.execute("""
            INSERT INTO logs (user_id, album_id, rating, review, listened_date)
            VALUES (?, ?, ?, ?, datetime('now'));
        """, (user_id, album_id, rating, review if review else None))

        session["success"] = "✅ Rating / review added!"

    conn.commit()
    conn.close()

    return redirect(url_for("album_detail", album_id=album_id))


@app.route("/album/<int:album_id>/review", methods=["POST"])
def submit_review(album_id):
    if not session.get("user_id"):
        return redirect(url_for("login"))

    user_id = session["user_id"]
    rating_raw = request.form.get("rating")
    review = request.form.get("review", "").strip()

    rating = None
    if rating_raw:
        try:
            rating = int(rating_raw)
        except:
            rating = None

    if rating is None and review == "":
        session["error"] = "Please select a rating and/or write a review."
        return redirect(url_for("album_detail", album_id=album_id))

    if review and (rating is None or rating < 1 or rating > 5):
        session["error"] = "You must include a rating between 1 and 5 when writing a review."
        return redirect(url_for("album_detail", album_id=album_id))

    if rating is not None and (rating < 1 or rating > 5):
        session["error"] = "Rating must be between 1 and 5."
        return redirect(url_for("album_detail", album_id=album_id))

    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT id
        FROM logs
        WHERE user_id = ?
          AND album_id = ?
          AND (rating IS NOT NULL OR review IS NOT NULL)
        ORDER BY listened_date DESC
        LIMIT 1;
    """, (user_id, album_id))
    existing = cur.fetchone()

    if existing:
        cur.execute("""
            UPDATE logs
            SET rating = ?,
                review = ?,
                listened_date = datetime('now')
            WHERE id = ?;
        """, (rating, review if review else None, existing["id"]))

        session["success"] = "✅ Rating / review updated!"
    else:
        cur.execute("""
            INSERT INTO logs (user_id, album_id, rating, review, listened_date)
            VALUES (?, ?, ?, ?, datetime('now'));
        """, (user_id, album_id, rating, review if review else None))

        session["success"] = "✅ Rating / review added!"

    conn.commit()
    conn.close()

    return redirect(url_for("album_detail", album_id=album_id))


@app.route("/signup", methods=["GET", "POST"])
def signup():
    error = None
    if request.method == "POST":
        username = request.form.get("username").strip()
        email = request.form.get("email").strip()
        password = request.form.get("password")

        if not username or not email or not password:
            error = "All fields are required."
        else:
            try:
                conn = connect_db()
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO users (username, email, password_hash)
                    VALUES (?, ?, ?);
                """, (username, email, password))
                conn.commit()

                user_id = cur.lastrowid
                conn.close()

                session["user_id"] = user_id
                session["username"] = username
                # new users are not admin by default
                session["is_admin"] = False
                return redirect(url_for("albums"))
            except sqlite3.IntegrityError:
                error = "Username or email already exists."

    return render_template("signup.html", error=error)

@app.route("/login", methods=["GET", "POST"])
def login():
    error = None

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        if not username or not password:
            error = "Username and password required."
        else:
            conn = connect_db()
            cur = conn.cursor()

            # try to include is_admin column if it exists
            try:
                cur.execute("""
                    SELECT id, password_hash, is_admin
                    FROM users
                    WHERE username = ?;
                """, (username,))
            except Exception:
                cur.execute("""
                    SELECT id, password_hash
                    FROM users
                    WHERE username = ?;
                """, (username,))

            user = cur.fetchone()
            conn.close()

            if user and password == user["password_hash"]:
                session["user_id"] = user["id"]
                session["username"] = username
                # set admin flag in session if available, otherwise default False
                try:
                    session["is_admin"] = bool(user["is_admin"])
                except Exception:
                    session["is_admin"] = False

                return redirect(url_for("albums"))
            else:
                error = "Invalid username or password."

    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("albums"))

@app.route("/search", methods=["POST"])
def search():
    term = request.form.get("term", "").strip()

    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT DISTINCT a.id, a.title, a.release_year, a.cover_image
        FROM albums a
        WHERE a.title LIKE ?
        ORDER BY a.release_year DESC;
    """, (f"%{term}%",))
    album_title_matches = cur.fetchall()

    cur.execute("""
        SELECT id
        FROM artists
        WHERE name LIKE ?;
    """, (f"%{term}%",))
    matched_artists = cur.fetchall()

    artist_album_matches = []
    if matched_artists:
        artist_ids = tuple(a["id"] for a in matched_artists)

        cur.execute(f"""
            SELECT DISTINCT a.id, a.title, a.release_year, a.cover_image
            FROM albums a
            JOIN album_artists aa ON a.id = aa.album_id
            WHERE aa.artist_id IN ({','.join(['?']*len(artist_ids))})
            ORDER BY a.release_year DESC;
        """, artist_ids)

        artist_album_matches = cur.fetchall()

    all_albums = {a["id"]: a for a in album_title_matches}
    for a in artist_album_matches:
        all_albums[a["id"]] = a

    cur.execute("""
        SELECT id, username, user_bio
        FROM users
        WHERE username LIKE ?
        ORDER BY username ASC;
    """, (f"%{term}%",))
    user_results = cur.fetchall()

    conn.close()

    return render_template(
        "search_results.html",
        albums=list(all_albums.values()),
        users=user_results,
        search_term=term
    )


@app.route("/feed")
def feed():
    if not session.get("user_id"):
        return redirect(url_for("login"))

    user_id = session["user_id"]
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT 
            u.id AS user_id,
            u.username AS username,
            'log' AS type,
            a.id AS album_id,
            a.title AS album_title,
            GROUP_CONCAT(ar.name, ', ') AS artist,
            l.rating AS rating,
            l.review AS review,
            l.listened_date AS created_at,
            NULL AS list_id,
            NULL AS list_name
        FROM logs l
        JOIN users u ON l.user_id = u.id
        JOIN albums a ON l.album_id = a.id
        JOIN album_artists aa ON a.id = aa.album_id
        JOIN artists ar ON aa.artist_id = ar.id
        WHERE l.user_id = ?
           OR l.user_id IN (
                SELECT following_id
                FROM user_follows
                WHERE follower_id = ?
           )
        GROUP BY l.id

        UNION ALL

        SELECT
            u.id AS user_id,
            u.username AS username,
            'list_create' AS type,
            NULL AS album_id,
            NULL AS album_title,
            NULL AS artist,
            NULL AS rating,
            NULL AS review,
            l.created_date AS created_at,
            l.id AS list_id,
            l.name AS list_name
        FROM lists l
        JOIN users u ON l.user_id = u.id
        WHERE (l.user_id = ?
           OR l.user_id IN (
                SELECT following_id
                FROM user_follows
                WHERE follower_id = ?
           ))
           AND l.is_public = 1

        UNION ALL

        SELECT
            u.id AS user_id,
            u.username AS username,
            'add_to_list' AS type,
            a.id AS album_id,
            a.title AS album_title,
            GROUP_CONCAT(ar.name, ', ') AS artist,
            NULL AS rating,
            NULL AS review,
            l.created_date AS created_at,
            l.id AS list_id,
            l.name AS list_name
        FROM lists l
        JOIN list_albums la ON la.list_id = l.id
        JOIN users u ON l.user_id = u.id
        JOIN albums a ON la.album_id = a.id
        JOIN album_artists aa ON a.id = aa.album_id
        JOIN artists ar ON aa.artist_id = ar.id
        WHERE (l.user_id = ?
           OR l.user_id IN (
                SELECT following_id
                FROM user_follows
                WHERE follower_id = ?
           ))
           AND l.is_public = 1
        GROUP BY la.list_id, la.album_id

        ORDER BY created_at DESC
        LIMIT 50;
    """, (user_id, user_id, user_id, user_id, user_id, user_id))

    feed = cur.fetchall()
    conn.close()

    return render_template("feed.html", feed=feed)

@app.route("/profile")
def profile():
    if not session.get("user_id"):
        return redirect(url_for("login"))

    user_id = session["user_id"]

    conn = connect_db()
    cur = conn.cursor()

    cur.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cur.fetchone()

    cur.execute("""
        SELECT a.title, l.rating, l.review, l.listened_date
        FROM logs l
        JOIN albums a ON l.album_id = a.id
        WHERE l.user_id = ?
        ORDER BY l.listened_date DESC;
    """, (user_id,))
    logs = cur.fetchall()

    cur.execute("""
        SELECT l.id, l.name, l.is_public, COUNT(la.album_id) AS album_count
        FROM lists l
        LEFT JOIN list_albums la ON l.id = la.list_id
        WHERE l.user_id = ?
        GROUP BY l.id, l.name, l.is_public;
    """, (user_id,))
    lists = cur.fetchall()

    cur.execute("""
        SELECT COUNT(*) FROM user_follows WHERE following_id = ?;
    """, (user_id,))
    follower_count = cur.fetchone()[0]

    cur.execute("""
        SELECT COUNT(*) FROM user_follows WHERE follower_id = ?;
    """, (user_id,))
    following_count = cur.fetchone()[0]

    conn.close()

    return render_template(
        "profile.html",
        user=user,
        logs=logs,
        lists=lists,
        follower_count=follower_count,
        following_count=following_count
)


@app.route("/user/<int:user_id>")
def user_profile(user_id):
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cur.fetchone()

    if not user:
        conn.close()
        return "User not found", 404

    cur.execute("""
        SELECT l.album_id, a.title, l.rating, l.review, l.listened_date
        FROM logs l
        JOIN albums a ON l.album_id = a.id
        WHERE l.user_id = ?
        ORDER BY l.listened_date DESC
        LIMIT 20;
    """, (user_id,))
    logs = cur.fetchall()

    cur.execute("""
        SELECT l.id, l.name, COUNT(la.album_id) AS album_count
        FROM lists l
        LEFT JOIN list_albums la ON l.id = la.list_id
        WHERE l.user_id = ? AND l.is_public = 1
        GROUP BY l.id;
    """, (user_id,))
    lists = cur.fetchall()

    is_following = False
    if session.get("user_id"):
        cur.execute("""
            SELECT 1 FROM user_follows
            WHERE follower_id = ? AND following_id = ?;
        """, (session["user_id"], user_id))
        is_following = cur.fetchone() is not None

    cur.execute("""
        SELECT COUNT(*) FROM user_follows WHERE following_id = ?;
    """, (user_id,))
    follower_count = cur.fetchone()[0]

    cur.execute("""
        SELECT COUNT(*) FROM user_follows WHERE follower_id = ?;
    """, (user_id,))
    following_count = cur.fetchone()[0]

    conn.close()

    return render_template(
        "user_profile.html",
        user=user,
        logs=logs,
        lists=lists,
        is_following=is_following,
        follower_count=follower_count,
        following_count=following_count
    )


    

@app.route("/follow/<int:user_id>", methods=["POST"])
def follow_user(user_id):
    if not session.get("user_id"):
        return redirect(url_for("login"))

    follower_id = session["user_id"]

    conn = connect_db()
    cur = conn.cursor()

    try:
        cur.execute("""
            INSERT INTO user_follows (follower_id, following_id)
            VALUES (?, ?);
        """, (follower_id, user_id))
        conn.commit()
    except:
        pass

    conn.close()
    return redirect(url_for("user_profile", user_id=user_id))


@app.route("/list/<int:list_id>")
def view_list(list_id):
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT l.id, l.name, l.is_public, u.username, u.id AS user_id
        FROM lists l
        JOIN users u ON l.user_id = u.id
        WHERE l.id = ?;
    """, (list_id,))
    lst = cur.fetchone()

    if not lst:
        conn.close()
        return "List not found", 404

    if lst["is_public"] == 0:
        if not session.get("user_id") or session["user_id"] != lst["user_id"]:
            conn.close()
            return "This list is private.", 403

    cur.execute("""
        SELECT a.id, a.title, a.cover_image, la.position
        FROM list_albums la
        JOIN albums a ON la.album_id = a.id
        WHERE la.list_id = ?
        ORDER BY la.position ASC;
    """, (list_id,))
    albums = cur.fetchall()

    conn.close()

    return render_template("list_detail.html", lst=lst, albums=albums)

@app.route("/album/<int:album_id>/add_to_list", methods=["POST"])
def add_album_to_list(album_id):
    if not session.get("user_id"):
        return redirect(url_for("login"))

    user_id = session["user_id"]

    existing_list_id = request.form.get("existing_list_id")
    list_name = request.form.get("list_name", "").strip()
    description = request.form.get("description", "").strip()
    is_public = 1 if request.form.get("is_public") == "on" else 0

    conn = connect_db()
    cur = conn.cursor()

    if existing_list_id:
        list_id = int(existing_list_id)

    elif list_name:
        cur.execute("""
            INSERT INTO lists (user_id, name, description, is_public, created_date)
            VALUES (?, ?, ?, ?, datetime('now'));
        """, (user_id, list_name, description, is_public))

        list_id = cur.lastrowid

    else:
        conn.close()
        return redirect(url_for("album_detail", album_id=album_id))

    cur.execute("""
        SELECT 1 FROM list_albums
        WHERE list_id = ? AND album_id = ?;
    """, (list_id, album_id))

    already_exists = cur.fetchone()

    if not already_exists:
        cur.execute("""
            INSERT INTO list_albums (list_id, album_id, position)
            VALUES (?, ?, 1);
        """, (list_id, album_id))

    conn.commit()
    conn.close()

    return redirect(url_for("view_list", list_id=list_id))


@app.route("/lists")
def browse_lists():
    filter_mode = request.args.get("filter", "all")  
    user_id = session.get("user_id")

    conn = connect_db()
    cur = conn.cursor()

    if filter_mode == "all" or not user_id:
        cur.execute("""
            SELECT 
                l.id, l.name, l.created_date,
                u.username,
                COUNT(la.album_id) AS album_count
            FROM lists l
            JOIN users u ON l.user_id = u.id
            LEFT JOIN list_albums la ON l.id = la.list_id
            WHERE l.is_public = 1
            GROUP BY l.id
            ORDER BY l.created_date DESC;
        """)
    
    else:
        cur.execute("""
            SELECT 
                l.id, l.name, l.created_date,
                u.username,
                COUNT(la.album_id) AS album_count
            FROM lists l
            JOIN users u ON l.user_id = u.id
            LEFT JOIN list_albums la ON l.id = la.list_id
            WHERE l.is_public = 1
              AND l.user_id IN (
                  SELECT following_id
                  FROM user_follows
                  WHERE follower_id = ?
              )
            GROUP BY l.id
            ORDER BY l.created_date DESC;
        """, (user_id,))

    lists = cur.fetchall()
    conn.close()

    return render_template(
        "lists.html",
        lists=lists,
        filter_mode=filter_mode
    )

@app.route("/profile/update_bio", methods=["POST"])
def update_bio():
    if not session.get("user_id"):
        return redirect(url_for("login"))

    bio = request.form.get("user_bio", "").strip()
    user_id = session["user_id"]

    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        UPDATE users
        SET user_bio = ?
        WHERE id = ?;
    """, (bio, user_id))

    conn.commit()
    conn.close()

    session["success"] = "✅ Bio updated!"
    return redirect(url_for("profile"))


@app.route("/followers/<int:user_id>")
def followers(user_id):
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT u.id, u.username
        FROM user_follows f
        JOIN users u ON f.follower_id = u.id
        WHERE f.following_id = ?;
    """, (user_id,))

    followers = cur.fetchall()
    conn.close()

    return render_template("followers_list.html", users=followers)


@app.route("/following/<int:user_id>")
def following(user_id):
    conn = connect_db()
    cur = conn.cursor()

    cur.execute("""
        SELECT u.id, u.username
        FROM user_follows f
        JOIN users u ON f.following_id = u.id
        WHERE f.follower_id = ?;
    """, (user_id,))

    following = cur.fetchall()
    conn.close()

    return render_template("following_list.html", users=following)


def admin_required():
    if not session.get("is_admin"):
        return False
    return True


@app.route('/admin')
def admin_dashboard():
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()

    cur.execute("SELECT id, title, release_year FROM albums ORDER BY title ASC;")
    albums = cur.fetchall()

    cur.execute("SELECT id, username, email FROM users ORDER BY username ASC;")
    users = cur.fetchall()

    conn.close()
    return render_template('admin_dashboard.html', albums=albums, users=users)


@app.route('/debug/session')
def debug_session():
    # Debug helper: returns current session keys and (if logged in) the DB is_admin value for the user
    debug = {k: session.get(k) for k in session.keys()}
    if session.get('user_id'):
        conn = connect_db()
        cur = conn.cursor()
        try:
            cur.execute('SELECT is_admin FROM users WHERE id = ?;', (session['user_id'],))
            row = cur.fetchone()
            debug['db_is_admin'] = bool(row['is_admin']) if row and 'is_admin' in row.keys() else None
        except Exception:
            debug['db_is_admin'] = None
        conn.close()

    return debug


@app.route('/admin/album/<int:album_id>/edit', methods=['GET', 'POST'])
def admin_edit_album(album_id):
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()

    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        release_year = request.form.get('release_year')
        cover_image = request.form.get('cover_image', '').strip()
        artist_names = request.form.get('artists', '').strip() 
        genre_ids = request.form.getlist('genres')

        try:
            if release_year == '':
                release_year_val = None
            else:
                release_year_val = int(release_year)
        except:
            release_year_val = None

        cur.execute("UPDATE albums SET title = ?, release_year = ?, cover_image = ? WHERE id = ?;",
                    (title, release_year_val, cover_image if cover_image else None, album_id))

        cur.execute('DELETE FROM album_artists WHERE album_id = ?;', (album_id,))

        if artist_names:
            artists_list = [name.strip() for name in artist_names.split(',') if name.strip()]
            
            for artist_name in artists_list:
                cur.execute("SELECT id FROM artists WHERE name = ?;", (artist_name,))
                existing_artist = cur.fetchone()
                
                if existing_artist:
                    artist_id = existing_artist['id']
                else:
                    cur.execute("INSERT INTO artists (name) VALUES (?);", (artist_name,))
                    artist_id = cur.lastrowid
                
                cur.execute("""
                    INSERT INTO album_artists (album_id, artist_id)
                    VALUES (?, ?);
                """, (album_id, artist_id))

        cur.execute('DELETE FROM album_genres WHERE album_id = ?;', (album_id,))

        for genre_id in genre_ids:
            if genre_id:
                cur.execute("""
                    INSERT INTO album_genres (album_id, genre_id)
                    VALUES (?, ?);
                """, (album_id, int(genre_id)))

        conn.commit()
        conn.close()
        session['success'] = '✅ Album updated.'
        return redirect(url_for('admin_dashboard'))

    cur.execute("SELECT * FROM albums WHERE id = ?;", (album_id,))
    album = cur.fetchone()

    if not album:
        conn.close()
        return 'Album not found', 404

    cur.execute("""
        SELECT ar.name
        FROM artists ar
        JOIN album_artists aa ON ar.id = aa.artist_id
        WHERE aa.album_id = ?;
    """, (album_id,))
    current_artists = cur.fetchall()
    current_artists_str = ', '.join([a['name'] for a in current_artists])

    cur.execute("""
        SELECT g.id
        FROM genres g
        JOIN album_genres ag ON g.id = ag.genre_id
        WHERE ag.album_id = ?;
    """, (album_id,))
    current_genre_ids = [g['id'] for g in cur.fetchall()]

    cur.execute("SELECT id, name FROM genres ORDER BY name ASC;")
    all_genres = cur.fetchall()

    conn.close()

    return render_template('admin_edit_album.html', 
                         album=album, 
                         current_artists=current_artists_str,
                         current_genre_ids=current_genre_ids,
                         all_genres=all_genres)


@app.route('/admin/album/<int:album_id>/delete', methods=['POST'])
def admin_delete_album(album_id):
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()

    cur.execute('DELETE FROM album_artists WHERE album_id = ?;', (album_id,))
    cur.execute('DELETE FROM album_genres WHERE album_id = ?;', (album_id,))
    cur.execute('DELETE FROM list_albums WHERE album_id = ?;', (album_id,))
    cur.execute('DELETE FROM logs WHERE album_id = ?;', (album_id,))
    cur.execute('DELETE FROM albums WHERE id = ?;', (album_id,))

    conn.commit()
    conn.close()

    session['success'] = '✅ Album deleted.'
    return redirect(url_for('admin_dashboard'))


@app.route('/admin/user/<int:user_id>/delete', methods=['POST'])
def admin_delete_user(user_id):
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()

    # delete logs
    cur.execute('DELETE FROM logs WHERE user_id = ?;', (user_id,))

    # delete lists and their list_albums
    cur.execute('SELECT id FROM lists WHERE user_id = ?;', (user_id,))
    lists = cur.fetchall()
    for l in lists:
        cur.execute('DELETE FROM list_albums WHERE list_id = ?;', (l['id'],))
    cur.execute('DELETE FROM lists WHERE user_id = ?;', (user_id,))

    # delete follows
    cur.execute('DELETE FROM user_follows WHERE follower_id = ? OR following_id = ?;', (user_id, user_id))

    # finally delete user
    cur.execute('DELETE FROM users WHERE id = ?;', (user_id,))

    conn.commit()
    conn.close()

    session['success'] = '✅ User and related data deleted.'
    return redirect(url_for('admin_dashboard'))


@app.route('/admin/user/<int:user_id>/delete_logs', methods=['POST'])
def admin_delete_user_logs(user_id):
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()
    cur.execute('DELETE FROM logs WHERE user_id = ?;', (user_id,))
    conn.commit()
    conn.close()

    session['success'] = '✅ User logs deleted.'
    return redirect(url_for('admin_dashboard'))


@app.route('/admin/log/<int:log_id>/delete', methods=['POST'])
def admin_delete_log(log_id):
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()
    cur.execute('DELETE FROM logs WHERE id = ?;', (log_id,))
    conn.commit()
    conn.close()

    session['success'] = '✅ Log deleted.'
    return redirect(request.referrer or url_for('admin_dashboard'))



@app.route('/admin/album/create', methods=['GET', 'POST'])
def admin_create_album():
    if not admin_required():
        return redirect(url_for('albums'))

    conn = connect_db()
    cur = conn.cursor()

    if request.method == 'POST':
        title = request.form.get('title', '').strip()
        release_year = request.form.get('release_year')
        cover_image = request.form.get('cover_image', '').strip()
        artist_names = request.form.get('artists', '').strip()  # Comma-separated artist names
        genre_ids = request.form.getlist('genres')    # Multiple genres

        if not title:
            session['error'] = 'Album title is required.'
            cur.execute("SELECT id, name FROM genres ORDER BY name ASC;")
            genres = cur.fetchall()
            conn.close()
            return render_template('admin_create_album.html', genres=genres)

        try:
            if release_year == '':
                release_year_val = None
            else:
                release_year_val = int(release_year)
        except:
            release_year_val = None

        cur.execute("""
            INSERT INTO albums (title, release_year, cover_image)
            VALUES (?, ?, ?);
        """, (title, release_year_val, cover_image if cover_image else None))

        album_id = cur.lastrowid

        if artist_names:
            artists_list = [name.strip() for name in artist_names.split(',') if name.strip()]
            
            for artist_name in artists_list:
                cur.execute("SELECT id FROM artists WHERE name = ?;", (artist_name,))
                existing_artist = cur.fetchone()
                
                if existing_artist:
                    artist_id = existing_artist['id']
                else:
                    cur.execute("INSERT INTO artists (name) VALUES (?);", (artist_name,))
                    artist_id = cur.lastrowid
                
                cur.execute("""
                    INSERT INTO album_artists (album_id, artist_id)
                    VALUES (?, ?);
                """, (album_id, artist_id))

        for genre_id in genre_ids:
            if genre_id:
                cur.execute("""
                    INSERT INTO album_genres (album_id, genre_id)
                    VALUES (?, ?);
                """, (album_id, int(genre_id)))

        conn.commit()
        conn.close()

        session['success'] = '✅ Album created successfully!'
        return redirect(url_for('admin_dashboard'))

    cur.execute("SELECT id, name FROM genres ORDER BY name ASC;")
    genres = cur.fetchall()
    
    conn.close()

    return render_template('admin_create_album.html', genres=genres)

if __name__ == "__main__":
    app.run(debug=True, host="127.0.0.1", port=5000)