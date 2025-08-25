# Contributing to Aurora Examples

🎉 Thanks for your interest in contributing! This repository contains code samples in multiple languages to help developers get started quickly with the **Aurora API**.

We welcome improvements, fixes, and new examples.

---

## 🚀 How to Contribute

1. **Fork this repository**  
   Click the **Fork** button on the top-right of the page.

2. **Clone your fork**  
   ```bash
   git clone https://github.com/<your-username>/aurora-examples.git
   cd aurora-examples
   ```

3. **Create a branch**

   ```bash
   git checkout -b feature/my-new-example
   ```

4. **Add your example**

   * Place it in the appropriate folder (`powershell/`, `bash/`, `python/`, `csharp/`, `java/`, `javascript/`, etc.).
   * Include a short `README.md` in that folder with:

     * What the example does
     * How to run it
     * Any prerequisites (dependencies, API keys, etc.)

5. **Commit your changes**

   ```bash
   git add .
   git commit -m "Add new example: <short description>"
   ```

6. **Push to your fork**

   ```bash
   git push origin feature/my-new-example
   ```

7. **Open a Pull Request**
   Go to the GitHub page for your fork and click **New Pull Request**.

---

## ✅ Guidelines

* Keep examples **simple and focused** (one main concept per file).
* Use clear, consistent naming:

  * `sample.ps1`, `sample.py`, `Sample.java`, etc.
* Add comments in the code to explain what’s happening.
* Don’t commit secrets or API keys — use environment variables where needed.
* Make sure `.gitignore` rules keep out build artifacts, IDE settings, and other clutter.

---

## 🛠 Development Notes

* Line endings are normalized with `.gitattributes`.
* Temporary files and build outputs are excluded via `.gitignore`.
* All code is licensed under the [MIT License](LICENSE).

---

## 💬 Questions?

If you’re unsure about something, open an [issue](../../issues) and let’s discuss it before you start coding.

Thanks for helping make Aurora easier for developers! 🚀