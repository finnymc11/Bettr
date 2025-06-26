
import firebase_admin
from firebase_admin import credentials, auth

cred = credentials.Certificate("{replace with filepath to key")
firebase_admin.initialize_app(cred)

def delete_multiple_users(user_ids):
    # Firebase Admin SDK can delete up to 100 users in one batch
    BATCH_SIZE = 100

    # Process in batches of 100 UIDs
    for i in range(0, len(user_ids), BATCH_SIZE):
        batch = user_ids[i:i + BATCH_SIZE]
        try:
            result = auth.delete_users(batch)
            print(f"Successfully deleted {result.success_count} users.")
            if result.failure_count > 0:
                print("Failures:")
                for err in result.errors:
                    print(f"UID: {batch[err.index]}, Error: {err.reason}")
        except Exception as e:
            print(f"Error deleting batch: {e}")




def get_all_user_uids():
    user_uids = []
    page = auth.list_users()  # First batch of users

    while page:
        for user in page.users:
            user_uids.append(user.uid)  # Collect UID
        
        # Get next batch (if available)
        page = page.get_next_page()

    return user_uids

def main():
    user_ids_to_delete = get_all_user_uids()
    print(f"Total users to delete: {len(user_ids_to_delete)}")
    delete_multiple_users(user_ids_to_delete)

if __name__ == "__main__":
    main()
