import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlTab", "imageTab", "urlPanel", "imagePanel", "sourceTypeField"]

  connect() {
    // Default to URL tab
    this.showUrl()
  }

  showUrl() {
    this.urlTabTarget.classList.add("border-blue-500", "text-blue-600")
    this.urlTabTarget.classList.remove("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
    
    this.imageTabTarget.classList.remove("border-blue-500", "text-blue-600")
    this.imageTabTarget.classList.add("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
    
    this.urlPanelTarget.classList.remove("hidden")
    this.imagePanelTarget.classList.add("hidden")
    
    this.sourceTypeFieldTarget.value = "url"
  }

  showImage() {
    this.imageTabTarget.classList.add("border-blue-500", "text-blue-600")
    this.imageTabTarget.classList.remove("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
    
    this.urlTabTarget.classList.remove("border-blue-500", "text-blue-600")
    this.urlTabTarget.classList.add("border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
    
    this.imagePanelTarget.classList.remove("hidden")
    this.urlPanelTarget.classList.add("hidden")
    
    this.sourceTypeFieldTarget.value = "image"
  }

  fileSelected(event) {
    const fileInput = event.target
    const file = fileInput.files[0]
    
    if (file) {
      const fileSelectedDiv = document.getElementById("file-selected")
      const filenameDisplay = document.getElementById("filename-display")
      
      if (fileSelectedDiv && filenameDisplay) {
        filenameDisplay.textContent = file.name
        fileSelectedDiv.classList.remove("hidden")
      }
    }
  }
}
