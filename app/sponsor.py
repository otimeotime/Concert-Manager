import tkinter as tk
from tkinter import ttk
import psycopg2
from psycopg2 import OperationalError

class SponsorLoginWindow:
    def __init__(self, root, error_label):
        self.root = root
        self.error_label = error_label
        self.login_window = tk.Toplevel(root)
        self.login_window.title("Sponsor Login")
        self.login_window.geometry("400x300")

        # Username label and entry
        username_label = tk.Label(self.login_window, text="Username", font=("Serif", 12))
        username_label.pack(pady=10)
        self.username_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.username_entry.pack(pady=10)

        # Password label and entry
        password_label = tk.Label(self.login_window, text="Password", font=("Serif", 12))
        password_label.pack(pady=10)
        self.password_entry = tk.Entry(self.login_window, show="*", font=("Serif", 12))
        self.password_entry.pack(pady=10)

        # Login button
        login_button = tk.Button(self.login_window, text="Login", font=("Serif", 12), command=self.login)
        login_button.pack(pady=20)

    def login(self):
        username = self.username_entry.get()
        password = self.password_entry.get()

        try:
            conn = psycopg2.connect(
                dbname="ConcertManagement",
                user=username,
                password=password,
                host="localhost",
                port="5432"
            )
            cursor = conn.cursor()
            self.login_window.destroy()
            SponsorWindow(self.root, conn, cursor, username)
        except OperationalError:
            self.error_label.config(text="Wrong username or password")
            self.login_window.destroy()
            self.root.deiconify()

class SponsorWindow:
    def __init__(self, root, conn, cursor, username):
        self.conn = conn
        self.cursor = cursor
        self.username = username
        self.new_window = tk.Toplevel(root)
        self.new_window.title("Sponsor")
        self.new_window.geometry("1024x768")

        # Add a back button to the upper left
        back_button = tk.Button(self.new_window, text="Back", font=("Serif", 12), command=lambda: self.close_window(root))
        back_button.pack(anchor="nw", padx=10, pady=10)
        
        # Add a welcome label
        label = tk.Label(self.new_window, text="Welcome, Sponsor!", font=("Serif", 30, "bold"))
        label.pack(pady=20)
        
        # Create a frame for the buttons
        button_frame = tk.Frame(self.new_window)
        button_frame.pack(pady=10)
        
        # Add text field for cid
        cid_label = tk.Label(button_frame, text="CID:", font=("Serif", 12))
        cid_label.pack(side="left", padx=5)
        self.cid_entry = tk.Entry(button_frame, font=("Serif", 12))
        self.cid_entry.pack(side="left", padx=5)
        
        # Add the "View dob" button
        view_dob_button = tk.Button(button_frame, text="View dob", font=("Serif", 12), command=self.view_dob)
        view_dob_button.pack(side="left", padx=5)
        
        # Add the "View artist" button
        view_artist_button = tk.Button(button_frame, text="View artist", font=("Serif", 12), command=self.view_artist)
        view_artist_button.pack(side="left", padx=5)
        
        # Add the "View sponsor" button
        view_sponsor_button = tk.Button(button_frame, text="View sponsor", font=("Serif", 12), command=self.view_sponsor)
        view_sponsor_button.pack(side="left", padx=5)
        
        # Add the "Performance" button
        performance_button = tk.Button(button_frame, text="Performance", font=("Serif", 12), command=self.view_performance)
        performance_button.pack(side="left", padx=5)
        
        # Add the "Act" button
        act_button = tk.Button(button_frame, text="Act", font=("Serif", 12), command=self.view_act)
        act_button.pack(side="left", padx=5)
        
        # Add the "Abort" button
        abort_button = tk.Button(button_frame, text="Abort", font=("Serif", 12), command=self.abort_transaction)
        abort_button.pack(side="left", padx=5)
        
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

        # Message label for PostgreSQL messages
        self.message_label = tk.Label(self.new_window, text="", font=("Serif", 12), fg="red")
        self.message_label.pack(pady=10)

    def view_dob(self):
        cid = self.cid_entry.get()
        self.viewaudiencesponsor(self.username, cid)

    def view_artist(self):
        cid = self.cid_entry.get()
        self.viewartist_sponsor(self.username, cid)

    def view_sponsor(self):
        cid = self.cid_entry.get()
        self.viewsponsor_sponsor(self.username, cid)

    def view_performance(self):
        cid = self.cid_entry.get()
        self.view_sponsor_performance(self.username, cid)

    def view_act(self):
        cid = self.cid_entry.get()
        self.view_sponsor_act(self.username, cid)

    def viewaudiencesponsor(self, bid, cid):
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Call the PostgreSQL function
        try:
            self.cursor.execute("SELECT * FROM viewaudiencesponsor(%s, %s)", (bid, cid))
            rows = self.cursor.fetchall()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
        
        # Get column names
        columns = [desc[0] for desc in self.cursor.description]
        
        # Update Treeview columns
        self.tree["columns"] = columns
        for col in columns:
            self.tree.heading(col, text=col, anchor="center")
            self.tree.column(col, anchor="center", width=100)
        
        # Insert data into the Treeview
        for row in rows:
            self.tree.insert("", "end", values=row)

    def viewartist_sponsor(self, bid, cid):
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Call the PostgreSQL function
        try:
            self.cursor.execute("SELECT * FROM viewartist_sponsor(%s, %s)", (bid, cid))
            rows = self.cursor.fetchall()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
        
        # Get column names
        columns = [desc[0] for desc in self.cursor.description]
        
        # Update Treeview columns
        self.tree["columns"] = columns
        for col in columns:
            self.tree.heading(col, text=col, anchor="center")
            self.tree.column(col, anchor="center", width=100)
        
        # Insert data into the Treeview
        for row in rows:
            self.tree.insert("", "end", values=row)

    def viewsponsor_sponsor(self, bid, cid):
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Call the PostgreSQL function
        try:
            self.cursor.execute("SELECT * FROM viewsponsor_sponsor(%s, %s)", (bid, cid))
            rows = self.cursor.fetchall()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
        
        # Get column names
        columns = [desc[0] for desc in self.cursor.description]
        
        # Update Treeview columns
        self.tree["columns"] = columns
        for col in columns:
            self.tree.heading(col, text=col, anchor="center")
            self.tree.column(col, anchor="center", width=100)
        
        # Insert data into the Treeview
        for row in rows:
            self.tree.insert("", "end", values=row)

    def view_sponsor_performance(self, bid, cid):
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Call the PostgreSQL function
        try:
            self.cursor.execute("SELECT * FROM view_sponsor_performance(%s, %s)", (bid, cid))
            rows = self.cursor.fetchall()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
        
        # Get column names
        columns = [desc[0] for desc in self.cursor.description]
        
        # Update Treeview columns
        self.tree["columns"] = columns
        for col in columns:
            self.tree.heading(col, text=col, anchor="center")
            self.tree.column(col, anchor="center", width=100)
        
        # Insert data into the Treeview
        for row in rows:
            self.tree.insert("", "end", values=row)

    def view_sponsor_act(self, bid, cid):
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Call the PostgreSQL function
        try:
            self.cursor.execute("SELECT * FROM view_sponsor_act(%s, %s)", (bid, cid))
            rows = self.cursor.fetchall()
            self.message_label.config(text=self.cursor.statusmessage, fg="green")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")
        
        # Get column names
        columns = [desc[0] for desc in self.cursor.description]
        
        # Update Treeview columns
        self.tree["columns"] = columns
        for col in columns:
            self.tree.heading(col, text=col, anchor="center")
            self.tree.column(col, anchor="center", width=100)
        
        # Insert data into the Treeview
        for row in rows:
            self.tree.insert("", "end", values=row)

    def abort_transaction(self):
        try:
            self.conn.rollback()
            self.message_label.config(text="Transaction aborted", fg="orange")
        except Exception as e:
            self.message_label.config(text=str(e), fg="red")

    def close_window(self, root):
        # Close the database connection
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        self.new_window.destroy()
        root.deiconify()