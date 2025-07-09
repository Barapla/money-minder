import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="budgets--preview"
export default class extends Controller {

  static targets = [ "name", "budgetType", "current", "debt", "limit", "icons", "colors",
                      "goal", "interestRate", "monthlyContribution",
                     "preview", "previewName", "previewBudgetType", "previewCurrent", 
                     "previewDebt", "previewLimit", "previewProgress", "previewProgressBar", 
                     "previewDebitStatus", "previewGoal", "previewInterestRate",
                      "previewMonthlyContribution" ]

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
    if (this.nameTarget.tagName === 'SELECT') {
      this.previewNameTarget.textContent = this.nameTarget.selectedOptions[0].textContent;
    } else {
      this.previewNameTarget.textContent = this.nameTarget.value || "Nuevo Presupuesto";
    }
    this.previewBudgetTypeTarget.textContent = this.budgetTypeTarget.selectedOptions[0].textContent;
  }

  updateCreditPreview(event) {
    const debt = parseFloat(this.debtTarget.value) || 0;
    const limit = parseFloat(this.limitTarget.value) || 0;
    const percentage = limit > 0 ? (debt / limit) * 100 : 0;
    
    this.previewDebtTarget.textContent = `$${debt.toFixed(2)}`;
    this.previewLimitTarget.textContent = `$${limit.toFixed(2)}`;
    this.previewProgressBarTarget.style.width = `${Math.min(percentage, 100)}%`;
  }

  updateDebitPreview(event) {
    const current = parseFloat(this.currentTarget.value) || 0;

    this.previewCurrentTarget.textContent = `$${current.toFixed(2)}`;

     if (!this.previewDebitStatusTarget) {
      return;
    }

    const previewStatusSpan = this.previewDebitStatusTarget.querySelector('span');

   

    if( current > 0) {
      previewStatusSpan.textContent = "✓ Con fondos";
      previewStatusSpan.classList.remove('bg-red-500/20', 'text-red-400');
      previewStatusSpan.classList.add('bg-emerald-500/20', 'text-emerald-400');
    } else {
      previewStatusSpan.textContent = "⚠ Sin fondos";
      previewStatusSpan.classList.remove('bg-emerald-500/20', 'text-emerald-400');
      previewStatusSpan.classList.add('bg-red-500/20', 'text-red-400');
    }
  }

  updateSavingsPreview(event) {
    const goal = parseFloat(this.goalTarget.value) || 0;
    const interestRate = parseFloat(this.interestRateTarget.value) || 0;
    const monthlyContribution = parseFloat(this.monthlyContributionTarget.value) || 0;

    // Calcular progreso
    const current = parseFloat(this.currentTarget.value) || 0;
    const progressPercentage = goal > 0 ? (current / goal) * 100 : 0;

    // Actualizar preview
    this.previewCurrentTarget.textContent = `$${current.toFixed(2)}`;
    this.previewGoalTarget.textContent = `$${goal.toFixed(2)}`;
    this.previewInterestRateTarget.textContent = `${interestRate.toFixed(2)}%`;
    this.previewMonthlyContributionTarget.textContent = `$${monthlyContribution.toFixed(2)}`;
    
    this.previewProgressTarget.textContent = `${progressPercentage.toFixed(1)}%`;
    this.previewProgressBarTarget.style.width = `${Math.min(progressPercentage, 100)}%`;
  }

}