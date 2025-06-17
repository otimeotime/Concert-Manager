import tkinter as tk
from tkinter import PhotoImage
from PIL import Image, ImageTk
import psycopg2
from psycopg2 import OperationalError
from director import DirectorLoginWindow
from artist import ArtistLoginWindow
from sponsor import SponsorLoginWindow
from audience import AudienceLoginWindow


class TicketBoxApp:
    def __init__(self, root):
        self.root = root
        self.root.title("TicketBox")
        self.root.geometry("1024x768")
        self.conn = None
        self.cursor = None

        # Load and resize the logo image
        image = Image.open("D:/db_project/app/image/logo.png")
        image = image.resize((100, 100), Image.LANCZOS)
        self.logo = ImageTk.PhotoImage(image)

        # Create a frame for the title and logo
        title_frame = tk.Frame(self.root)
        title_frame.pack(pady=20)

        # Add the logo to the frame
        logo_label = tk.Label(title_frame, image=self.logo)
        logo_label.pack(side="top")

        # Add the title to the frame
        title_label = tk.Label(title_frame, text="Concert Box", font=("Serif", 50, "bold"))
        title_label.pack(side="top")

        # Add the "Who are you?" text below the title
        subtitle_label = tk.Label(title_frame, text="Who are you?", font=("Serif", 30, "bold"))
        subtitle_label.pack(side="top", pady=40)

        # Create a frame for the buttons
        button_frame = tk.Frame(self.root)
        button_frame.pack(pady=20)

        # Add buttons to the frame
        button_director = tk.Button(button_frame, text="Director", font=("Serif", 20), width=10, height=5, command=self.open_director_window)
        button_director.pack(side="left", padx=10)

        button_artist = tk.Button(button_frame, text="Artist", font=("Serif", 20), width=10, height=5, command=self.open_artist_login)
        button_artist.pack(side="left", padx=10)

        button_sponsor = tk.Button(button_frame, text="Sponsor", font=("Serif", 20), width=10, height=5, command=self.open_sponsor_login)
        button_sponsor.pack(side="left", padx=10)

        button_audience = tk.Button(button_frame, text="Audience", font=("Serif", 20), width=10, height=5, command=self.open_audience_login)
        button_audience.pack(side="left", padx=10)

        # Error label for login error messages
        self.error_label = tk.Label(self.root, text="", font=("Serif", 12), fg="red")
        self.error_label.pack(pady=10)

    def close_existing_connection(self):
        if self.cursor:
            self.cursor.close()
            self.cursor = None
        if self.conn:
            self.conn.close()
            self.conn = None

    def open_director_window(self):
        self.close_existing_connection()
        self.root.withdraw()
        DirectorLoginWindow(self.root, self.error_label)

    def open_artist_login(self):
        self.close_existing_connection()
        ArtistLoginWindow(self.root, self.error_label)

    def open_sponsor_login(self):
        self.close_existing_connection()
        SponsorLoginWindow(self.root, self.error_label)

    def open_audience_login(self):
        self.close_existing_connection()
        AudienceLoginWindow(self.root, self.error_label)

    def open_help_window(self):
        help_window = tk.Toplevel(self.root)
        help_window.title("Help")
        help_window.geometry("600x400")
        help_label = tk.Label(help_window, text="This is the help window.", font=("Serif", 20))
        help_label.pack(pady=20)
        back_button = tk.Button(help_window, text="Back", font=("Serif", 20), command=help_window.destroy)
        back_button.pack(pady=20)

if __name__ == "__main__":
    root = tk.Tk()
    app = TicketBoxApp(root)
    root.mainloop()