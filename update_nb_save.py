import json
import uuid

notebook_path = r'c:\Users\LENOVO\Crop-APP\crop_prediction.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

save_cells = [
    {
        "cell_type": "markdown",
        "metadata": {},
        "source": ["## Save the Model\n", "Save the trained `best_model` locally for FastAPI backend."]
    },
    {
        "cell_type": "code",
        "execution_count": None,
        "metadata": {},
        "outputs": [],
        "source": [
            "import joblib\n",
            "joblib.dump(best_model, 'crop_model.pkl')\n",
            "print(\"Model saved as crop_model.pkl\")"
        ]
    }
]

# Check if already present
already_present = False
for c in nb['cells']:
    source_text = "".join(c.get("source", []))
    if "joblib.dump(best_model" in source_text:
        already_present = True
        break

if already_present:
    print("Save cells already exist in the notebook.")
else:
    # Assign a unique id to each new cell
    for cell in save_cells:
        cell['id'] = str(uuid.uuid4())[:8]

    # Insert this before the Interactive Crop Prediction section or just at the end.
    # Actually, the user asked to add it to the end of the notebook. So I will append it.
    nb['cells'].extend(save_cells)

    with open(notebook_path, 'w', encoding='utf-8') as f:
        json.dump(nb, f, indent=1)

    print("Saved model cells injected into the notebook.")
