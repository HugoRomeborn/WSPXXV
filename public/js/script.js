function addIngredient() {

    const container = document.getElementById("ingredients");

    const div = document.createElement("div");
    div.className = "ingredient";

    div.innerHTML = `
    <input type="text" name="ingredients[][amount]" placeholder="Mängd">
    <input type="text" name="ingredients[][unit]" placeholder="Enhet">
    <input type="text" name="ingredients[][name]" placeholder="Ingrediens">
  `;

    container.appendChild(div);
}