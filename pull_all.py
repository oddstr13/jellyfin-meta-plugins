#!/usr/bin/env python3
import os
import subprocess
import requests
import time


#print(repos)
available = []
fetched = []

def update(_name, url=None):
    print('-----')
    print(_name)
    print(description)
    print(url)

    if not os.path.exists(_name):
        subprocess.run(['git', 'clone', url, _name], check=True)
        subprocess.run(['git', 'remote', 'rename', 'origin', 'upstream'], cwd=_name, check=True)

    subprocess.run(['git', 'checkout', '-f', '**/*.csproj', '*.csproj'], cwd=_name, check=False)
    subprocess.run(['git', 'checkout', '-f', 'build.yaml'], cwd=_name, check=False)
    subprocess.run(['git', 'checkout', 'master'], cwd=_name, check=True)
    subprocess.run(['git', 'fetch', '--all', '--tags'], cwd=_name, check=True)
    subprocess.run(['git', 'pull', 'upstream', 'master', '--ff-only'], cwd=_name, check=True)
    fetched.append(_name)

failed = []

page_num = 1
per_page = 100
PAGINATION_URL = 'https://api.github.com/orgs/jellyfin/repos?sort=created&per_page={per}&page={page}'
next = PAGINATION_URL.format(per=per_page, page=page_num)
while next:
    resp = requests.get(next)
    
    page_num += 1
    next = PAGINATION_URL.format(per=per_page, page=page_num)
    #next = None  # TODO: Add pagination support

    repos = resp.json()

    if len(repos) < per_page:
        next = None


    for repo in repos:
        _name = repo.get('name')
        description = repo.get('description')
        url = repo.get('clone_url')
        if _name.startswith('jellyfin-plugin-'):
            try:
                available.append(_name)
                #update(_name, url)
                pass
            except Exception as e:
                failed.append((_name, e))

for repo in available:
    if not os.path.exists(repo):
        print("Available:", repo)
#exit()
for repo in os.listdir('.'):
    if repo in fetched:
        continue

    if not os.path.isdir(repo):
        continue

    if not repo.startswith('jellyfin-plugin-'):
        continue
    try:
        if not repo in available:
            print("Not available:", repo)
        #update(repo)
    except Exception as e:
        failed.append((repo, e))


if failed:
    print("The following repositories failed to update:")
    for repo, e in failed:
        print(repo, e)
