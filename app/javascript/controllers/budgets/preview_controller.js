import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="budgets--preview"
export default class extends Controller {

  static targets = [ "name", "budgetType", "current", "limit", "icons", "colors",
                     "preview", "previewName", "previewCurrent", "previewLimit", 
                     "previewProgressBar", "previewBudgetType" ]

  connect() {
    console.log("Budgets Preview Controller connected");
  }

  // Actions que se llaman desde el HTML
  selectIcon(event) {
    const button = event.currentTarget;
    
    // Remover selección anterior
    this.iconsTargets.forEach(btn => {
      btn.classList.remove('bg-purple-500/20', 'border-purple-500/50');
      btn.classList.add('bg-bunker-800/60', 'border-bunker-700/50');
    });
    
    // Agregar selección actual
    button.classList.remove('bg-bunker-800/60', 'border-bunker-700/50');
    button.classList.add('bg-purple-500/20', 'border-purple-500/50');
    
    // Actualizar preview
    const previewIcon = this.previewTarget.querySelector('span');
    if (previewIcon) {
        previewIcon.textContent = button.textContent;
    }
  }
  
  selectColor(event) {
    const button = event.currentTarget;
    
    // Actualizar preview
    const previewDiv = this.previewTarget;
    if (previewDiv) {
        // Remover todas las clases que empiecen con 'bg-'
        const bgClasses = Array.from(previewDiv.classList).filter(cls => cls.startsWith('bg-'));
        previewDiv.classList.remove(...bgClasses);
        
        // Usar el data attribute del botón seleccionado
        const newColorClass = button.dataset.colorClass;
        if (newColorClass) {
            previewDiv.classList.add(newColorClass);
        }
    }
  }

  updatePreview(event) {
    const current = parseFloat(this.currentTarget.value) || 0;
    const limit = parseFloat(this.limitTarget.value) || 0;
    const percentage = limit > 0 ? (current / limit) * 100 : 0;
    
    this.previewNameTarget.textContent = this.nameTarget.value || "Nuevo Presupuesto";
    this.previewBudgetTypeTarget.textContent = this.budgetTypeTarget.selectedOptions[0].textContent;
    this.previewCurrentTarget.textContent = `$${current.toFixed(2)}`;
    this.previewLimitTarget.textContent = `$${limit.toFixed(2)}`;
    this.previewProgressBarTarget.style.width = `${Math.min(percentage, 100)}%`;
  }


}