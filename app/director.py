import tkinter as tk
from tkinter import ttk
import psycopg2
from psycopg2 import OperationalError

class DirectorLoginWindow:
    def __init__(self, root, error_label):
        self.root = root
        self.error_label = error_label
        self.login_window = tk.Toplevel(root)
        self.login_window.title("Director Login")
        self.login_window.geometry("400x300")

        # Password label and entry
        password_label = tk.Label(self.login_window, text="Password", font=("Serif", 12))
        password_label.pack(pady=10)
        self.password_entry = tk.Entry(self.login_window, show="*", font=("Serif", 12))
        self.password_entry.pack(pady=10)

        # Login button
        login_button = tk.Button(self.login_window, text="Login", font=("Serif", 12), command=self.login)
        login_button.pack(pady=20)

    def login(self):
        password = self.password_entry.get()

        try:
            conn = psycopg2.connect(
                dbname="ConcertManagement",
                user='maindirector',
                password=password,
                host="localhost",
                port="5432"
            )
            cursor = conn.cursor()
            self.login_window.destroy()
            DirectorWindow(self.root, conn, cursor)
        except OperationalError:
            self.error_label.config(text="Wrong username or password")
            self.login_window.destroy()
            self.root.deiconify()

class DirectorWindow:
    def __init__(self, root, conn, cursor):
        self.conn = conn
        self.cursor = cursor
        self.new_window = tk.Toplevel(root)
        self.new_window.title("Director")
        self.new_window.geometry("1024x768")

        # Add a back button to the upper left
        back_button = tk.Button(self.new_window, text="Back", font=("Serif", 12), command=lambda: self.close_window(root))
        back_button.pack(anchor="nw", padx=10, pady=10)
        
        # Add a welcome label
        label = tk.Label(self.new_window, text="Welcome, Director!", font=("Serif", 30, "bold"))
        label.pack(pady=20)
        
        # Create a frame for the buttons
        button_frame = tk.Frame(self.new_window)
        button_frame.pack(pady=10)
        
        # List of table names
        self.tables = ["concert", "artist", "contract", "act", "performance", "brand", "sponsor", "technicle", "broadcast", "venue", "ticket", "audience", "own"]
        
        # Create buttons for each table
        for table in self.tables:
            button = tk.Button(button_frame, text=table, font=("Serif", 12), command=lambda t=table: self.populate_table(t))
            button.pack(side="left", padx=5)
        
        # Create a frame for the table and scrollbar
        table_frame = tk.Frame(self.new_window)
        table_frame.pack(pady=10, fill="both", expand=True)
        
        # Create the Treeview widget with a horizontal scrollbar
        self.tree = ttk.Treeview(table_frame, show="headings", height=10)  # Set height to limit the number of visible rows
        self.tree.pack(side="left", fill="both", expand=True)
        
        scrollbar_x = tk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        scrollbar_x.pack(side="bottom", fill="x")
        self.tree.configure(xscrollcommand=scrollbar_x.set)

        # Display connection status
        connection_status_label = tk.Label(self.new_window, text="Connected to the database successfully!", fg="green", font=("Serif", 12))
        connection_status_label.pack(pady=10)

        # Populate the main table initially
        self.populate_table("concert")

        # Add a button to open the edit window
        edit_button = tk.Button(self.new_window, text="Edit Table", font=("Serif", 12), command=self.open_edit_window)
        edit_button.pack(pady=10)

    def populate_table(self, table_name):
        self.current_table = table_name  # Store the current table name
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Get column names
        self.cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{table_name}' ORDER BY ordinal_position")
        columns = [row[0] for row in self.cursor.fetchall()]
        
        # Update Treeview columns
        self.tree["columns"] = columns
        for col in columns:
            self.tree.heading(col, text=col, anchor="center")
            self.tree.column(col, anchor="center", width=100)
        
        # Execute the query
        self.cursor.execute(f"SELECT * FROM {table_name}")
        rows = self.cursor.fetchall()
        
        # Insert data into the Treeview
        for row in rows:
            self.tree.insert("", "end", values=row)

    def open_edit_window(self):
        EditWindow(self.new_window, self.current_table, self.conn, self.cursor)

    def close_window(self, root):
        # Close the database connection
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        
        self.new_window.destroy()
        root.deiconify()

class EditWindow:
    def __init__(self, parent, table_name, conn, cursor):
        self.conn = conn
        self.cursor = cursor
        self.table_name = table_name
        self.edit_window = tk.Toplevel(parent)
        self.edit_window.title(f"Edit {table_name}")
        self.edit_window.geometry("600x400")
        
        label = tk.Label(self.edit_window, text=f"Editing table: {table_name}", font=("Serif", 20))
        label.pack(pady=20)
        
        # Create a frame for the buttons
        button_frame = tk.Frame(self.edit_window)
        button_frame.pack(pady=10)
        
        # Add, Delete, Update buttons
        if self.table_name != 'audience':
            add_button = tk.Button(button_frame, text="Add", font=("Serif", 12), command=self.show_add_fields)
            add_button.pack(side="left", padx=5)

            update_button = tk.Button(button_frame, text="Update", font=("Serif", 12), command=self.show_update_primary_key_fields)
            update_button.pack(side="left", padx=5)
        
        delete_button = tk.Button(button_frame, text="Delete", font=("Serif", 12), command=self.show_delete_fields)
        delete_button.pack(side="left", padx=5)

        # Frame to hold dynamic fields
        self.fields_frame = tk.Frame(self.edit_window)
        self.fields_frame.pack(pady=10)

        # Message label for success or error messages
        self.message_label = tk.Label(self.edit_window, text="", font=("Serif", 12))
        self.message_label.pack(pady=10)

        # Close button
        close_button = tk.Button(self.edit_window, text="Close", font=("Serif", 12), command=self.edit_window.destroy)
        close_button.pack(pady=10)

        # Abort button
        abort_button = tk.Button(self.edit_window, text="Abort", font=("Serif", 12), command=self.abort_transaction)
        abort_button.pack(pady=10)

    def show_add_fields(self):
        # Clear existing fields
        for widget in self.fields_frame.winfo_children():
            widget.destroy()
        
        # Get column names
        self.cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{self.table_name}' ORDER BY ordinal_position")
        columns = [row[0] for row in self.cursor.fetchall()]
        
        # Create entry fields for each column
        self.entries = {}
        for col in columns:
            label = tk.Label(self.fields_frame, text=col, font=("Serif", 12))
            label.pack()
            entry = tk.Entry(self.fields_frame, font=("Serif", 12))
            entry.pack()
            self.entries[col] = entry
        
        # Add button to insert the new row
        insert_button = tk.Button(self.fields_frame, text="Insert", font=("Serif", 12), command=self.insert_row)
        insert_button.pack(pady=10)

    def insert_row(self):
        # Get values from entry fields
        columns = list(self.entries.keys())
        values = [self.entries[col].get() for col in columns]
        
        # Create the INSERT INTO query
        query = f"INSERT INTO {self.table_name} ({', '.join(columns)}) VALUES ({', '.join(['%s'] * len(values))})"
        
        try:
            self.cursor.execute(query, values)
            self.conn.commit()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
            print(self.cursor.statusmessage)  # Print status message to the terminal
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
            print(e)  # Print error message to the terminal

    def show_delete_fields(self):
        # Clear existing fields
        for widget in self.fields_frame.winfo_children():
            widget.destroy()
        
        # Get primary key columns
        self.cursor.execute(f"""
            SELECT kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            WHERE tc.table_name = '{self.table_name}' AND tc.constraint_type = 'PRIMARY KEY'
        """)
        primary_keys = [row[0] for row in self.cursor.fetchall()]
        
        # Create entry fields for each primary key column
        self.entries = {}
        for pk in primary_keys:
            label = tk.Label(self.fields_frame, text=pk, font=("Serif", 12))
            label.pack()
            entry = tk.Entry(self.fields_frame, font=("Serif", 12))
            entry.pack()
            self.entries[pk] = entry
        
        # Add button to delete the row
        delete_button = tk.Button(self.fields_frame, text="Delete", font=("Serif", 12), command=self.delete_row)
        delete_button.pack(pady=10)

    def delete_row(self):
        # Get values from entry fields
        primary_keys = list(self.entries.keys())
        values = [self.entries[pk].get() for pk in primary_keys]
        
        # Create the DELETE FROM query
        conditions = " AND ".join([f"{pk} = %s" for pk in primary_keys])
        query = f"DELETE FROM {self.table_name} WHERE {conditions}"
        
        try:
            self.cursor.execute(query, values)
            self.conn.commit()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
            print(self.cursor.statusmessage)  # Print status message to the terminal
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
            print(e)  # Print error message to the terminal

    def show_update_primary_key_fields(self):
        # Clear existing fields
        for widget in self.fields_frame.winfo_children():
            widget.destroy()
        
        # Get primary key columns
        self.cursor.execute(f"""
            SELECT kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
            WHERE tc.table_name = '{self.table_name}' AND tc.constraint_type = 'PRIMARY KEY'
        """)
        primary_keys = [row[0] for row in self.cursor.fetchall()]
        
        # Create entry fields for each primary key column
        self.entries = {}
        for pk in primary_keys:
            label = tk.Label(self.fields_frame, text=pk, font=("Serif", 12))
            label.pack()
            entry = tk.Entry(self.fields_frame, font=("Serif", 12))
            entry.pack()
            self.entries[pk] = entry
        
        # Add button to fetch the row for updating
        fetch_button = tk.Button(self.fields_frame, text="Fetch", font=("Serif", 12), command=self.fetch_row_for_update)
        fetch_button.pack(pady=10)

    def fetch_row_for_update(self):
        # Get values from entry fields
        primary_keys = list(self.entries.keys())
        values = [self.entries[pk].get() for pk in primary_keys]
        
        # Create the SELECT query
        conditions = " AND ".join([f"{pk} = %s" for pk in primary_keys])
        query = f"SELECT * FROM {self.table_name} WHERE {conditions}"
        
        try:
            self.cursor.execute(query, values)
            row = self.cursor.fetchone()
            if row:
                # Clear existing fields
                for widget in self.fields_frame.winfo_children():
                    widget.destroy()
                
                # Get column names
                self.cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{self.table_name}' ORDER BY ordinal_position")
                columns = [row[0] for row in self.cursor.fetchall()]
                
                # Create entry fields for each column with existing values
                self.entries = {}
                for col, val in zip(columns, row):
                    label = tk.Label(self.fields_frame, text=col, font=("Serif", 12))
                    label.pack()
                    entry = tk.Entry(self.fields_frame, font=("Serif", 12))
                    entry.insert(0, val)
                    entry.pack()
                    self.entries[col] = entry
                
                # Add button to update the row
                update_button = tk.Button(self.fields_frame, text="Update", font=("Serif", 12), command=self.update_row)
                update_button.pack(pady=10)
            else:
                self.message_label.config(text="No matching entry found.", fg="red")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
            print(e)  # Print error message to the terminal

    def update_row(self):
        # Get values from entry fields
        columns = list(self.entries.keys())
        values = [self.entries[col].get() for col in columns]
        
        # Create the UPDATE query
        set_clause = ", ".join([f"{col} = %s" for col in columns])
        primary_keys = [col for col in columns if col in self.entries]
        conditions = " AND ".join([f"{pk} = %s" for pk in primary_keys])
        query = f"UPDATE {self.table_name} SET {set_clause} WHERE {conditions}"
        
        try:
            self.cursor.execute(query, values + [self.entries[pk].get() for pk in primary_keys])
            self.conn.commit()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
            print(self.cursor.statusmessage)  # Print status message to the terminal
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
            print(e)  # Print error message to the terminal

    def abort_transaction(self):
        try:
            self.conn.rollback()
            self.message_label.config(text="Transaction aborted", fg="orange")
            print("Transaction aborted")  # Print abort message to the terminal
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
            print(e)  # Print error message to the terminal

    def close_window(self):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        self.edit_window.destroy()