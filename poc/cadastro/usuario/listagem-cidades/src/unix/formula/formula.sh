#!/bin/sh

runFormula() {
  if [[ "$UF" == 'MG' ]]; then
    echo '["Uberlândia", "Uberaba", "Araguari"]'
  elif [[ "$UF" == 'SP' ]]; then
    echo '["Ribeirão Preto", "Franca", "São Paulo", "Bauru"]'
  fi
}
