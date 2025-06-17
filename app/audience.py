import tkinter as tk
from tkinter import ttk
import psycopg2
from psycopg2 import OperationalError
from tkinter import messagebox

class AudienceLoginWindow:
    def __init__(self, root, error_label):
        self.root = root
        self.error_label = error_label
        self.login_window = tk.Toplevel(root)
        self.login_window.title("Audience Login")
        self.login_window.geometry("400x400")

        # Username label and entry
        username_label = tk.Label(self.login_window, text="Username", font=("Serif", 12))
        username_label.pack(pady=5)
        self.username_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.username_entry.pack(pady=5)

        # Password label and entry
        password_label = tk.Label(self.login_window, text="Password", font=("Serif", 12))
        password_label.pack(pady=5)
        self.password_entry = tk.Entry(self.login_window, show="*", font=("Serif", 12))
        self.password_entry.pack(pady=5)

        # Login button
        login_button = tk.Button(self.login_window, text="Login", font=("Serif", 12), command=self.login)
        login_button.pack(pady=20)

        # Register button
        register_button = tk.Button(self.login_window, text="Register", font=("Serif", 12), command=self.show_register_fields)
        register_button.pack(pady=20)

    def show_register_fields(self):
        # Clear existing fields
        for widget in self.login_window.winfo_children():
            widget.destroy()

        # Username label and entry
        username_label = tk.Label(self.login_window, text="Username", font=("Serif", 12))
        username_label.pack(pady=5)
        self.username_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.username_entry.pack(pady=5)

        # Password label and entry
        password_label = tk.Label(self.login_window, text="Password", font=("Serif", 12))
        password_label.pack(pady=5)
        self.password_entry = tk.Entry(self.login_window, show="*", font=("Serif", 12))
        self.password_entry.pack(pady=5)

        # Last Name label and entry
        last_name_label = tk.Label(self.login_window, text="Last Name", font=("Serif", 12))
        last_name_label.pack(pady=5)
        self.last_name_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.last_name_entry.pack(pady=5)

        # First Name label and entry
        first_name_label = tk.Label(self.login_window, text="First Name", font=("Serif", 12))
        first_name_label.pack(pady=5)
        self.first_name_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.first_name_entry.pack(pady=5)

        # DOB label and entry
        dob_label = tk.Label(self.login_window, text="Date of Birth (YYYY-MM-DD)", font=("Serif", 12))
        dob_label.pack(pady=5)
        self.dob_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.dob_entry.pack(pady=5)

        # Register button
        register_button = tk.Button(self.login_window, text="Register", font=("Serif", 12), command=self.register)
        register_button.pack(pady=20)

        # Back to Login button
        back_to_login_button = tk.Button(self.login_window, text="Back to Login", font=("Serif", 12), command=self.show_login_fields)
        back_to_login_button.pack(pady=20)

    def show_login_fields(self):
        # Clear existing fields
        for widget in self.login_window.winfo_children():
            widget.destroy()

        # Username label and entry
        username_label = tk.Label(self.login_window, text="Username", font=("Serif", 12))
        username_label.pack(pady=5)
        self.username_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.username_entry.pack(pady=5)

        # Password label and entry
        password_label = tk.Label(self.login_window, text="Password", font=("Serif", 12))
        password_label.pack(pady=5)
        self.password_entry = tk.Entry(self.login_window, show="*", font=("Serif", 12))
        self.password_entry.pack(pady=5)

        # Login button
        login_button = tk.Button(self.login_window, text="Login", font=("Serif", 12), command=self.login)
        login_button.pack(pady=20)

        # Register button
        register_button = tk.Button(self.login_window, text="Register", font=("Serif", 12), command=self.show_register_fields)
        register_button.pack(pady=20)

    def register(self):
        username = self.username_entry.get()
        password = self.password_entry.get()
        last_name = self.last_name_entry.get()
        first_name = self.first_name_entry.get()
        dob = self.dob_entry.get()

        try:
            conn = psycopg2.connect(
                dbname="ConcertManagement",
                user="guest",
                password="123",
                host="localhost",
                port="5432"
            )
            cursor = conn.cursor()
            cursor.execute("SELECT MAX(audience_id) FROM audience")
            max_aid = cursor.fetchone()[0]
            if max_aid is None:
                new_aid = "000001"
            else:
                new_aid = str(int(max_aid) + 1).zfill(6)

            cursor.execute(
                "INSERT INTO audience(audience_id, username, pass_word, last_name, first_name, dob, join_date) VALUES (%s, %s, %s, %s, %s, %s, CURRENT_DATE)",
                (new_aid, username, password, last_name, first_name, dob)
            )
            conn.commit()
            self.error_label.config(text="Registration successful!", fg="green")
            self.show_login_fields()
        except Exception as e:
            self.error_label.config(text=f"An error occurred: {e}", fg="red")
            conn.rollback()
        finally:
            cursor.close()
            conn.close()

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
            cursor.execute("SELECT audience_id FROM audience WHERE username = %s", (username,))
            audience_id = cursor.fetchone()[0]
            self.login_window.destroy()
            AudienceWindow(self.root, conn, cursor, username, audience_id)
        except OperationalError:
            self.error_label.config(text="Wrong username or password")
            self.login_window.destroy()
            self.root.deiconify()

    def show_register_fields(self):
        # Clear existing widgets
        for widget in self.login_window.winfo_children():
            widget.destroy()

        # Username label and entry
        username_label = tk.Label(self.login_window, text="Username", font=("Serif", 12))
        username_label.pack(pady=5)
        self.username_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.username_entry.pack(pady=5)

        # Password label and entry
        password_label = tk.Label(self.login_window, text="Password", font=("Serif", 12))
        password_label.pack(pady=5)
        self.password_entry = tk.Entry(self.login_window, show="*", font=("Serif", 12))
        self.password_entry.pack(pady=5)

        # Last Name label and entry
        last_name_label = tk.Label(self.login_window, text="Last Name", font=("Serif", 12))
        last_name_label.pack(pady=5)
        self.last_name_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.last_name_entry.pack(pady=5)

        # First Name label and entry
        first_name_label = tk.Label(self.login_window, text="First Name", font=("Serif", 12))
        first_name_label.pack(pady=5)
        self.first_name_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.first_name_entry.pack(pady=5)

        # DOB label and entry
        dob_label = tk.Label(self.login_window, text="Date of Birth (YYYY-MM-DD)", font=("Serif", 12))
        dob_label.pack(pady=5)
        self.dob_entry = tk.Entry(self.login_window, font=("Serif", 12))
        self.dob_entry.pack(pady=5)

        # Register button
        register_button = tk.Button(self.login_window, text="Register", font=("Serif", 12), command=self.register)
        register_button.pack(pady=20)

    def register(self):
        username = self.username_entry.get()
        password = self.password_entry.get()
        last_name = self.last_name_entry.get()
        first_name = self.first_name_entry.get()
        dob = self.dob_entry.get()

        try:
            conn = psycopg2.connect(
                dbname="ConcertManagement",
                user="guest",
                password="123",
                host="localhost",
                port="5432"
            )
            cursor = conn.cursor()
            cursor.execute("SELECT MAX(audience_id) FROM audience")
            max_audience_id = cursor.fetchone()[0]
            if max_audience_id is None:
                new_audience_id = "000001"
            else:
                new_audience_id = str(int(max_audience_id) + 1).zfill(6)

            cursor.execute(
                "INSERT INTO audience (audience_id, username, pass_word, last_name, first_name, dob, join_date) VALUES (%s, %s, %s, %s, %s, %s, CURRENT_DATE)",
                (new_audience_id, username, password, last_name, first_name, dob)
            )
            conn.commit()
            self.error_label.config(text="Registration successful", fg="green")
            self.login_window.destroy()
            self.root.deiconify()
        except Exception as e:
            self.error_label.config(text=f"An error occurred: {e}", fg="red")
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()

class AudienceWindow:
    def __init__(self, root, conn, cursor, username, audience_id):
        self.conn = conn
        self.cursor = cursor
        self.username = username
        self.audience_id = audience_id
        self.first_name = username.split('.')[0].capitalize()  # Extract and capitalize the first name
        self.new_window = tk.Toplevel(root)
        self.new_window.title("Audience")
        self.new_window.geometry("1024x768")

        # Add a back button to the upper left
        back_button = tk.Button(self.new_window, text="Back", font=("Serif", 12), command=lambda: self.close_window(root))
        back_button.pack(anchor="nw", padx=10, pady=10)
        
        # Add a welcome label
        label = tk.Label(self.new_window, text=f"Welcome, {self.first_name}!", font=("Serif", 30, "bold"))
        label.pack(pady=20)
        
        # Create a frame for the buttons
        button_frame = tk.Frame(self.new_window)
        button_frame.pack(pady=10)
        
        # Add the "Concert" button
        concert_button = tk.Button(button_frame, text="Concert", font=("Serif", 12), command=self.view_concert)
        concert_button.pack(side="left", padx=5)
        
        # Add the "View Info" button
        view_info_button = tk.Button(button_frame, text="View Info", font=("Serif", 12), command=self.viewinfoaudience)
        view_info_button.pack(side="left", padx=5)
        
        # Add the "Ticket" button
        ticket_button = tk.Button(button_frame, text="Ticket", font=("Serif", 12), command=self.view_ticket)
        ticket_button.pack(side="left", padx=5)
        
        # Add the "Buy Ticket" button
        buy_ticket_button = tk.Button(button_frame, text="Buy Ticket", font=("Serif", 12), command=self.open_buy_ticket_window)
        buy_ticket_button.pack(side="left", padx=5)
        
        # Add the "Remove Ticket" button
        remove_ticket_button = tk.Button(button_frame, text="Remove Ticket", font=("Serif", 12), command=self.open_remove_ticket_window)
        remove_ticket_button.pack(side="left", padx=5)
        
        # Add the "View Purchased Ticket" button
        view_purchased_ticket_button = tk.Button(button_frame, text="View Purchased Ticket", font=("Serif", 12), command=self.view_purchased_ticket)
        view_purchased_ticket_button.pack(side="left", padx=5)
        
        # Add the "View Artist" button
        view_artist_button = tk.Button(button_frame, text="View Artist", font=("Serif", 12), command=self.view_artist_audience)
        view_artist_button.pack(side="left", padx=5)
        
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

        # CID label and entry for viewing artist
        cid_label = tk.Label(button_frame, text="CID", font=("Serif", 12))
        cid_label.pack(side="left", padx=5)
        self.cid_entry = tk.Entry(button_frame, font=("Serif", 12))
        self.cid_entry.pack(side="left", padx=5)

    def view_concert(self):
        self.populate_table("concert")

    def view_ticket(self):
        self.populate_table("ticket")

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

    def viewinfoaudience(self):
        try:
            self.cursor.execute("SELECT * FROM viewinfoaudience(%s)", (self.audience_id,))
            rows = self.cursor.fetchall()
            if rows:
                # Clear existing data
                for item in self.tree.get_children():
                    self.tree.delete(item)
                
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
                
                self.message_label.config(text="Audience info loaded successfully.", fg="green")
            else:
                self.message_label.config(text="No information found for this audience.", fg="orange")
        except Exception as e:
            self.message_label.config(text=f"An error occurred: {e}", fg="red")

    def open_buy_ticket_window(self):
        self.buy_ticket_window = tk.Toplevel(self.new_window)
        self.buy_ticket_window.title("Buy Ticket")
        self.buy_ticket_window.geometry("400x300")

        # Ticket ID label and entry
        ticket_id_label = tk.Label(self.buy_ticket_window, text="Ticket ID", font=("Serif", 12))
        ticket_id_label.pack(pady=5)
        self.ticket_id_entry = tk.Entry(self.buy_ticket_window, font=("Serif", 12))
        self.ticket_id_entry.pack(pady=5)

        # Quantity label and entry
        quantity_label = tk.Label(self.buy_ticket_window, text="Quantity", font=("Serif", 12))
        quantity_label.pack(pady=5)
        self.quantity_entry = tk.Entry(self.buy_ticket_window, font=("Serif", 12))
        self.quantity_entry.pack(pady=5)

        # Purchase button
        purchase_button = tk.Button(self.buy_ticket_window, text="Purchase", font=("Serif", 12), command=self.purchase_ticket)
        purchase_button.pack(pady=20)

    def purchase_ticket(self):
        ticket_id = self.ticket_id_entry.get()
        quantity = self.quantity_entry.get()
        try:
            self.cursor.execute("SELECT buyticket(%s, %s, %s)", (ticket_id, self.audience_id, quantity))
            self.conn.commit()
            self.message_label.config(text="Ticket purchased successfully.", fg="green")
            self.buy_ticket_window.destroy()
        except Exception as e:
            self.message_label.config(text=f"An error occurred: {e}", fg="red")

    def open_remove_ticket_window(self):
        self.remove_ticket_window = tk.Toplevel(self.new_window)
        self.remove_ticket_window.title("Remove Ticket")
        self.remove_ticket_window.geometry("400x300")

        # Ticket ID label and entry
        ticket_id_label = tk.Label(self.remove_ticket_window, text="Ticket ID", font=("Serif", 12))
        ticket_id_label.pack(pady=5)
        self.ticket_id_entry = tk.Entry(self.remove_ticket_window, font=("Serif", 12))
        self.ticket_id_entry.pack(pady=5)

        # New Amount label and entry
        new_amount_label = tk.Label(self.remove_ticket_window, text="New Amount", font=("Serif", 12))
        new_amount_label.pack(pady=5)
        self.new_amount_entry = tk.Entry(self.remove_ticket_window, font=("Serif", 12))
        self.new_amount_entry.pack(pady=5)

        # Buy Date label and entry
        buy_date_label = tk.Label(self.remove_ticket_window, text="Buy Date", font=("Serif", 12))
        buy_date_label.pack(pady=5)
        self.buy_date_entry = tk.Entry(self.remove_ticket_window, font=("Serif", 12))
        self.buy_date_entry.pack(pady=5)

        # Remove button
        remove_button = tk.Button(self.remove_ticket_window, text="Remove", font=("Serif", 12), command=self.remove_ticket)
        remove_button.pack(pady=20)

    def remove_ticket(self):
        ticket_id = self.ticket_id_entry.get()
        new_amount = self.new_amount_entry.get()
        buy_date = self.buy_date_entry.get()
        try:
            self.cursor.execute("SELECT removeticket(%s, %s, %s, %s)", (ticket_id, self.audience_id, buy_date, new_amount))
            self.conn.commit()
            self.message_label.config(text="Ticket removed successfully.", fg="green")
            self.remove_ticket_window.destroy()
        except Exception as e:
            self.message_label.config(text=f"An error occurred: {e}", fg="red")

    def view_purchased_ticket(self):
        try:
            self.cursor.execute("SELECT * FROM viewticket(%s)", (self.audience_id,))
            rows = self.cursor.fetchall()
            if rows:
                # Clear existing data
                for item in self.tree.get_children():
                    self.tree.delete(item)
                
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
                
                self.message_label.config(text="Purchased tickets loaded successfully.", fg="green")
            else:
                self.message_label.config(text="No purchased tickets found for this audience.", fg="orange")
        except Exception as e:
            self.message_label.config(text=f"An error occurred: {e}", fg="red")

    def view_artist_audience(self):
        cid = self.cid_entry.get()
        try:
            self.cursor.execute("SELECT * FROM view_artist_audience(%s)", (cid,))
            rows = self.cursor.fetchall()
            if rows:
                # Clear existing data
                for item in self.tree.get_children():
                    self.tree.delete(item)
                
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
                
                self.message_label.config(text="Artist info loaded successfully.", fg="green")
            else:
                self.message_label.config(text="No artist information found for this concert.", fg="orange")
        except Exception as e:
            self.message_label.config(text=f"An error occurred: {e}", fg="red")

    def abort_transaction(self):
        try:
            self.conn.rollback()
            self.message_label.config(text="The transaction has been successfully aborted.", fg="green")
        except Exception as e:
            self.message_label.config(text=f"An error occurred while aborting the transaction: {e}", fg="red")

    def close_window(self, root):
        # Close the database connection
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        self.new_window.destroy()
        root.deiconify()