import os
import sys
import shutil
import json
import zipfile
import tempfile
from urllib.request import urlopen, Request
from urllib.error import URLError
from tkinter import *
from tkinter import messagebox, ttk, filedialog

class AddonUpdater:
    def __init__(self):
        self.window = Tk()
        self.window.title("RP Status Installer")
        self.window.geometry("600x250")
        self.window.resizable(False, False)
        
        # Configuration - Direct ZIP download without Git
        self.DOWNLOAD_URL = "https://github.com/codexkeeper/RPStatus/archive/refs/heads/main.zip"
        self.config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "updater_config.json")
        
        # Initialize paths
        self.addons_path = ''
        
        # Load config
        self.load_config()
        
        # Setup UI
        self.setup_ui()

    def load_config(self):
        """Load last used AddOns path"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                self.addons_path = config.get('addons_path', '')
        except:
            self.addons_path = ''

    def save_config(self):
        """Save current AddOns path"""
        try:
            config_dir = os.path.dirname(self.config_file)
            if not os.path.exists(config_dir):
                os.makedirs(config_dir)
            with open(self.config_file, 'w') as f:
                json.dump({'addons_path': self.addons_path}, f)
        except Exception as e:
            print(f"Failed to save config: {e}")

    def setup_ui(self):
        main_frame = Frame(self.window, padx=20, pady=20)
        main_frame.pack(expand=True, fill='both')
        
        # Title
        title = Label(main_frame, text="RP Status Installer", font=("Arial", 14, "bold"))
        title.pack(pady=(0, 20))
        
        # AddOns Path Selection Frame
        path_frame = Frame(main_frame)
        path_frame.pack(fill='x', pady=(0, 20))
        
        path_label = Label(path_frame, text="AddOns Folder:", font=("Arial", 10))
        path_label.pack(side=LEFT, padx=(0, 10))
        
        self.path_var = StringVar(value=self.addons_path or "Please select your AddOns folder")
        self.path_entry = Entry(path_frame, textvariable=self.path_var, width=50)
        self.path_entry.pack(side=LEFT, fill='x', expand=True)
        
        browse_button = Button(path_frame, text="Browse", command=self.browse_path)
        browse_button.pack(side=LEFT, padx=(5, 0))
        
        # Status text
        self.status_label = Label(main_frame, text="Choose your AddOns folder to begin", 
                                font=("Arial", 10))
        self.status_label.pack(pady=(0, 10))
        
        # Install/Update button
        self.update_button = Button(main_frame, text="Install / Update", 
                                  command=self.install_or_update,
                                  width=20, height=1, 
                                  font=("Arial", 10, "bold"))
        self.update_button.pack(pady=10)

    def browse_path(self):
        """Open folder selection dialog specifically for AddOns folder"""
        path = filedialog.askdirectory(
            title="Select your Interface/AddOns folder",
            initialdir=self.addons_path if self.addons_path else "/"
        )
        if path:
            # Verify it's an AddOns folder
            if os.path.basename(path) != "AddOns":
                messagebox.showwarning("Wrong Folder", 
                    "Please select the 'AddOns' folder in your WoW installation.\n"
                    "It should be under: Interface/AddOns")
                return
                
            self.addons_path = path
            self.path_var.set(path)
            self.save_config()

    def download_file(self):
        """Download the ZIP file from GitHub"""
        try:
            headers = {'User-Agent': 'Mozilla/5.0'}  # Simple user agent to avoid rejections
            req = Request(self.DOWNLOAD_URL, headers=headers)
            
            with tempfile.NamedTemporaryFile(delete=False, suffix='.zip') as tmp_file:
                with urlopen(req, timeout=30) as response:
                    shutil.copyfileobj(response, tmp_file)
                return tmp_file.name
        except URLError as e:
            raise Exception(f"Download failed: Check your internet connection\nError: {str(e)}")
        except Exception as e:
            raise Exception(f"Download failed: {str(e)}")

    def install_addon(self, zip_path):
        """Extract the addon to the WoW AddOns folder"""
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                # Get the root folder name in the zip
                root_folder = zip_ref.namelist()[0].split('/')[0]
                
                # Create temporary directory for extraction
                with tempfile.TemporaryDirectory() as tmpdirname:
                    zip_ref.extractall(tmpdirname)
                    
                    # Source of rpstatus folder
                    src_folder = os.path.join(tmpdirname, root_folder, "rpstatus")
                    dst_folder = os.path.join(self.addons_path, "rpstatus")
                    
                    # Check if this is an update or fresh install
                    is_update = os.path.exists(dst_folder)
                    
                    # Remove old version if it exists
                    if is_update:
                        shutil.rmtree(dst_folder)
                    
                    # Copy new version
                    shutil.copytree(src_folder, dst_folder)
                    
                    return is_update
        except Exception as e:
            raise Exception(f"Installation failed: {str(e)}")
        finally:
            try:
                os.unlink(zip_path)
            except:
                pass

    def install_or_update(self):
        """Main installation/update function"""
        if not self.addons_path or not os.path.exists(self.addons_path):
            messagebox.showerror("Error", "Please select your AddOns folder first")
            return
        
        self.update_button.config(state='disabled')
        self.status_label.config(text="Starting installation process...")
        self.window.update()
        
        try:
            # Download
            self.status_label.config(text="Downloading addon...")
            self.window.update()
            zip_path = self.download_file()
            
            # Install
            self.status_label.config(text="Installing addon...")
            self.window.update()
            is_update = self.install_addon(zip_path)
            
            # Success message
            if is_update:
                message = "RP Status has been updated successfully!"
            else:
                message = "RP Status has been installed successfully!"
            
            self.status_label.config(text=message)
            messagebox.showinfo("Success", message)
            
        except Exception as e:
            error_msg = str(e)
            self.status_label.config(text="Installation failed!")
            messagebox.showerror("Error", f"Installation failed:\n{error_msg}")
        
        finally:
            self.update_button.config(state='normal')
            
    def run(self):
        self.window.mainloop()

if __name__ == "__main__":
    updater = AddonUpdater()
    updater.run()