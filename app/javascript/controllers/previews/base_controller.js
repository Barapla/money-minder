import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="previews--base"
export default class extends Controller {
    static targets = [
        "title", "subtitle", "icons", "colors",
        "preview", "previewTitle", "previewSubtitle"
    ]

    updatePreview(event) {

        if (this.titleTarget.tagName === 'SELECT') {
            this.previewTitleTarget.textContent = this.titleTarget.selectedOptions[0].textContent;
        } else {
            this.previewTitleTarget.textContent = this.titleTarget.value || "";
        }

        if (this.subtitleTarget.tagName === 'SELECT') {
            this.previewSubtitleTarget.textContent = this.subtitleTarget.selectedOptions[0].textContent;
        } else {
            this.previewSubtitleTarget.textContent = this.subtitleTarget.value || "";
        }
    }

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
}