# Causal Inference Workflow in R

이 프로젝트는 R을 사용한 인과추론(Causal Inference) 분석을 Nextflow와 WDL 워크플로우로 구현한 예제입니다. [r-causal.org](https://www.r-causal.org/)의 내용을 기반으로 하여 실제 워크플로우 환경에서 실행할 수 있도록 구성되었습니다.

## 📋 프로젝트 개요

이 워크플로우는 다음과 같은 인과추론 기법들을 시연합니다:

1. **데이터 생성**: 직업훈련 프로그램의 효과를 분석하기 위한 합성 데이터 생성
2. **탐색적 데이터 분석**: 변수들의 분포와 상관관계 분석
3. **성향점수 매칭**: 교란변수를 조정하여 인과효과 추정
4. **결과 요약**: 다양한 방법들의 결과 비교 및 시각화

## 🏗️ 프로젝트 구조

```
causal-inference-workflow/
├── Dockerfile                 # R 환경과 필요한 패키지들을 포함한 컨테이너
├── nextflow.config           # Nextflow 설정 파일
├── main.nf                   # Nextflow 워크플로우 정의
├── causal_inference.wdl      # WDL 워크플로우 정의
├── scripts/                  # R 분석 스크립트들
│   ├── 01_generate_data.R    # 합성 데이터 생성
│   ├── 02_exploratory_analysis.R  # 탐색적 데이터 분석
│   ├── 03_propensity_matching.R   # 성향점수 매칭
│   └── 04_final_results.R    # 최종 결과 요약
├── build_docker.sh           # Docker 이미지 빌드 스크립트
├── run_nextflow.sh          # Nextflow 실행 스크립트
├── run_wdl.sh               # WDL 실행 스크립트
├── test_standalone.R        # 독립 실행 테스트 스크립트
└── README.md                # 이 파일
```

## 🔧 필요한 도구들

### 기본 요구사항
- Docker
- R (독립 실행시)

### 워크플로우 엔진 (선택사항)
- **Nextflow**: [설치 가이드](https://www.nextflow.io/docs/latest/getstarted.html)
- **Cromwell** (WDL용): [다운로드](https://github.com/broadinstitute/cromwell/releases)

## 🚀 실행 방법

### 1. Docker 이미지 빌드

먼저 필요한 R 패키지들이 포함된 Docker 이미지를 빌드합니다:

```bash
chmod +x build_docker.sh
./build_docker.sh
```

### 2. Nextflow로 실행

```bash
chmod +x run_nextflow.sh
./run_nextflow.sh
```

### 3. WDL/Cromwell로 실행

```bash
chmod +x run_wdl.sh
./run_wdl.sh
```

### 4. 독립 실행 (R만 사용)

Docker나 워크플로우 엔진 없이 R만으로 실행:

```bash
Rscript test_standalone.R
```

## 📊 생성되는 결과물

워크플로우 실행 후 `results/` 디렉토리에 다음 파일들이 생성됩니다:

### 시각화 파일 (PNG)
- `covariate_distributions.png`: 처리군별 공변량 분포
- `outcome_by_treatment.png`: 처리군별 결과변수 분포
- `correlation_matrix.png`: 변수간 상관관계 매트릭스
- `balance_*.png`: 매칭 전후 균형 비교
- `propensity_score_distribution.png`: 성향점수 분포
- `treatment_effect_comparison.png`: 처리효과 추정치 비교

### 데이터 파일 (CSV)
- `summary_statistics.csv`: 기술통계량
- `matching_regression_results.csv`: 매칭 회귀분석 결과
- `final_summary_table.csv`: 최종 결과 요약표

### 보고서 (TXT)
- `final_report.txt`: 전체 분석 결과 요약 보고서

## 🧪 분석 내용 설명

### 1. 데이터 생성 (`01_generate_data.R`)
- 1,000명의 가상 개인 데이터 생성
- 나이, 교육수준, 이전 소득이 직업훈련 참여와 결과에 영향
- 실제 처리효과는 $3,000로 설정

### 2. 탐색적 분석 (`02_exploratory_analysis.R`)
- 처리군과 대조군 간 공변량 분포 비교
- 단순 평균 차이 계산 (편향된 추정치)
- 변수간 상관관계 분석

### 3. 성향점수 매칭 (`03_propensity_matching.R`)
- 로지스틱 회귀로 성향점수 추정
- 1:1 최근접 이웃 매칭 수행
- 매칭 전후 균형 검정
- 매칭된 데이터로 처리효과 추정

### 4. 결과 비교 (`04_final_results.R`)
- 실제 효과, 단순 추정치, 매칭 추정치 비교
- 편향(bias)과 신뢰구간 계산
- 최종 보고서 생성

## 📈 예상 결과

- **실제 처리효과**: $3,000
- **단순 추정치**: 편향됨 (교란변수로 인해)
- **성향점수 매칭 추정치**: 실제 효과에 더 가까움

## 🔍 주요 R 패키지

- **MatchIt**: 성향점수 매칭
- **cobalt**: 균형 진단
- **ggplot2**: 데이터 시각화
- **dplyr**: 데이터 조작
- **broom**: 모델 결과 정리

## 🎯 학습 목표

이 워크플로우를 통해 다음을 학습할 수 있습니다:

1. **인과추론의 기본 개념**: 교란변수와 선택편향
2. **성향점수 매칭**: 관찰연구에서 인과효과 추정
3. **워크플로우 관리**: Nextflow/WDL을 이용한 재현가능한 분석
4. **컨테이너화**: Docker를 이용한 환경 표준화
5. **결과 시각화**: ggplot2를 이용한 효과적인 그래프 작성

## 🛠️ 커스터마이징

### 데이터 수정
`01_generate_data.R`에서 다음을 수정할 수 있습니다:
- 샘플 크기 (`n`)
- 실제 처리효과 (`true_effect`)
- 변수들의 분포 모수

### 분석 방법 추가
새로운 인과추론 방법을 추가하려면:
1. 새 R 스크립트 작성
2. Nextflow/WDL 워크플로우에 프로세스 추가
3. Docker 이미지에 필요한 패키지 추가

## 📚 참고 자료

- [Causal Inference in R](https://www.r-causal.org/)
- [MatchIt 패키지 문서](https://kosukeimai.github.io/MatchIt/)
- [Nextflow 문서](https://www.nextflow.io/docs/latest/)
- [WDL 문서](https://openwdl.org/)

## 🤝 기여하기

이 프로젝트에 기여하고 싶으시다면:
1. Fork 후 새 브랜치 생성
2. 변경사항 커밋
3. Pull Request 제출

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
