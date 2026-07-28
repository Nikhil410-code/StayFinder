import sqlite3
import os

DB_PATH = "stayfinder.db"

def run_migration():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database file '{DB_PATH}' not found.")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Find the property 'NA study home PG'
    cursor.execute("SELECT id, name, area, address, lat, lng FROM properties WHERE name LIKE '%NA study home%'")
    row = cursor.fetchone()
    
    if not row:
        print("Property 'NA study home PG' not found in database.")
        conn.close()
        return

    pid, name, area, address, old_lat, old_lng = row
    print(f"Found property: ID={pid}, Name='{name}'")
    print(f"Current values: Area='{area}', Address='{address}', Lat={old_lat}, Lng={old_lng}")

    # Correct coordinates to Yelahanka coordinates:
    # NMIT coordinates: lat=13.1288782, lng=77.5872496
    new_lat = 13.1288782
    new_lng = 77.5872496
    new_area = "Yelahanka"

    print(f"Updating to: Area='{new_area}', Lat={new_lat}, Lng={new_lng}...")
    cursor.execute(
        "UPDATE properties SET area = ?, lat = ?, lng = ? WHERE id = ?",
        (new_area, new_lat, new_lng, pid)
    )
    conn.commit()
    print("Update successful!")
    conn.close()

if __name__ == "__main__":
    run_migration()
