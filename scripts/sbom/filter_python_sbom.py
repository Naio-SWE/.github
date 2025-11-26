#!/usr/bin/env python3
"""
Filter and enhance Python SBOM with license data from pip-licenses.
"""

import json
import sys


def load_installed_packages(freeze_file):
    """Load package names from pip freeze output."""
    installed = set()
    with open(freeze_file) as f:
        for line in f:
            if '==' in line:
                pkg_name = line.split('==')[0].lower().replace('-', '_')
                installed.add(pkg_name)
    return installed


def load_license_map(licenses_file):
    """Load license data from pip-licenses JSON output."""
    license_map = {}
    try:
        with open(licenses_file) as f:
            licenses_data = json.load(f)
            for pkg in licenses_data:
                name = pkg.get('Name', '').lower().replace('-', '_')
                license_map[name] = {
                    'license': pkg.get('License', 'UNKNOWN'),
                    'author': pkg.get('Author', ''),
                    'url': pkg.get('URL', '')
                }
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    return license_map


def filter_and_enhance_sbom(sbom_file, installed, license_map):
    """Filter SBOM to installed packages and enhance with license data."""
    with open(sbom_file) as f:
        sbom = json.load(f)
    
    filtered = []
    for comp in sbom.get('components', []):
        if comp.get('type') != 'library':
            continue
        
        purl = comp.get('purl', '')
        if not purl.startswith('pkg:pypi/'):
            continue
        
        pkg_name = purl.split('pkg:pypi/')[1].split('@')[0].lower().replace('-', '_')
        if pkg_name not in installed:
            continue
        
        # Enhance with license data if missing
        if pkg_name in license_map and not comp.get('licenses'):
            lic_info = license_map[pkg_name]
            if lic_info['license'] and lic_info['license'] != 'UNKNOWN':
                comp['licenses'] = [{
                    'license': {
                        'id': lic_info['license']
                    }
                }]
        
        filtered.append(comp)
    
    sbom['components'] = filtered
    return sbom, len(filtered)


def main():
    freeze_file = '/tmp/python-packages.txt'
    licenses_file = '/tmp/python-licenses.json'
    sbom_file = '/tmp/python-sbom.json'
    output_file = '/tmp/python-filtered.json'
    
    installed = load_installed_packages(freeze_file)
    license_map = load_license_map(licenses_file)
    sbom, count = filter_and_enhance_sbom(sbom_file, installed, license_map)
    
    with open(output_file, 'w') as f:
        json.dump(sbom, f, indent=2)
    
    print(f"Python: {count} packages")


if __name__ == '__main__':
    main()
