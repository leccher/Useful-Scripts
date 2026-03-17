#!/bin/bash
echo -e "\e[32mAdding custom .bashrc configuration...\e[0m"
echo -e "\e[32mSource: $(realpath .bashrc_custom)\e[0m"
# Aggiungi il source del file .bashrc_custom al .bashrc principale
if ! grep -q "source $(realpath .bashrc_custom)" ~/.bashrc; then
    echo -e "\e[32mAdding source line to ~/.bashrc...\e[0m"
    echo "source $(realpath .bashrc_custom)" >> ~/.bashrc
else
    echo -e "\e[33mSource line already exists in ~/.bashrc, skipping...\e[0m"
fi